# frozen_string_literal: true

module ImageWrangler
  module Transformers
    # Using MiniMagick tools for image processing
    module MiniMagick
      #
      # Recipe for rendered component, expected to be a hash eg:
      # {
      #   filepath: '/path/to/my-small-thumb.jpg',
      #   options: {
      #     'read_options' => {
      #        'density' => 72,
      #        'antialias' => nil
      #     },
      #     'geometry' => '100x100',
      #     'gamma' => 0.1,
      #     '+profile' => %w(8BIMTEXT IPTC IPTCTEXT XMP),
      #     'profile' => 'icc:/path/to/profile.icc',
      #     'sharpen' => '1x0.5'
      #    },
      #    'relegated_options' => {
      #      'strip' => nil
      #    }
      # }
      #
      # Options can be prefixed with '-' or '+' but hyphens are ignored.
      #
      # 'preprocess' directives can be passed when, eg handling vector files
      #
      # Also note: order of operations is important for IM. If color profile
      # conversions are being made, supply the 'profile' option with an array
      # when converting between tricky profiles, eg:
      # {
      #   'profile' => ['transitional.icc', 'rgb.icc']
      # }
      #
      require "tempfile"

      # Individual component
      class Variant < ImageWrangler::Transformers::Variant
        # Order of operations is important for IM convert so we
        # handle the various groups in the following sequence
        #
        # Relegated options include '-strip' and others which would normally
        # come at the end of the command line and prior to output filename
        attr_reader :grouped_options, :read_options, :relegated_options, :unrecognized_options

        OPTION_GROUP_ORDER = %w[
          image_settings
          image_operators
          image_sequence_operators
        ].freeze

        def initialize(config = OPTS, options = OPTS)
          super(config, options)

          @command = nil
          @tool = ::MiniMagick::Tool::Convert
          @my_option = ImageWrangler::Transformers::MiniMagick::Option
          @read_options = Hash.new { |hash, key| hash[key] = [] }
          @relegated_options = Hash.new { |hash, key| hash[key] = [] }
          @grouped_options = Hash.new { |hash, key| hash[key] = [] }
        end

        # remove nil values for argument-less options
        def merged_options(options = @grouped_options)
          ordered = ordered_options(options)
          ordered.map { |opt| [opt.to_s, opt.value] }.flatten.compact
        end

        def ordered_options(options = @grouped_options)
          return EMPTY_ARRAY if options.empty?

          ordered = []

          OPTION_GROUP_ORDER.each do |og|
            ordered << options[og] unless options[og].empty?
          end

          ordered.flatten
        end

        def prepare_tool(source_filepath = source_image.filepath)
          tool = @tool.new

          # Prepend processing args if available
          tool.merge! merged_options(@read_options)

          # Use the validated image filepath
          tool << source_filepath

          # There are a few ways to do this in MiniMagick, using merge! is
          # the most flexible although requires some care when constructing
          # the options/values
          tool.merge! merged_options(@grouped_options)

          # Add the relegated options last
          tool.merge! merged_options(@relegated_options)

          # Finally, add the output filepath
          tool << filepath

          tool
        end

        def process
          tool = prepare_tool

          # Persist the command we're using
          @command = tool.command.join(" ")

          tool.call do |_stdout, stderr, status|
            raise StandardError, stderr unless status.zero?

            # Gather data about the resulting file
            inspect_result
          end
        end

        def speak(msg, options = OPTS)
          verbose = options[:verbose] || false
          return unless verbose
          puts self.class.name
          puts msg
        end

        def supplied_options
          @supplied_options ||= @config.fetch(:options, OPTS).dup
        end

        def valid?
          errors.empty?
        end

        def validate!
          validate_empty_options
          validate_options
        end

        def validate_empty_options
          errors.add(:options, "cannot be empty") if supplied_options.empty?
        end

        def build_options(options, option_group = @grouped_options)
          return if options.empty?

          options.each_pair do |key, value|
            next if skip_option?(key)

            if @my_option.recognized?(key.to_s)
              # Supplied values can be either String, Array or nil
              # Coercing nils to Array doesn't work, so send a special
              # string instead. See Option#value
              Array(value || "_x_").each do |val|
                option = @my_option.new(key.to_s, val)
                option_group[option.option_group].push(option)
              end
            else
              @unrecognized_options.push(key)
            end
          end
        end

        def validate_options
          @unrecognized_options = []

          # Handle preprocessing options, eg vector density settings
          read_opts = supplied_options.delete("read_options") || OPTS
          build_options(read_opts, @read_options)

          # Handle relegated options, those which come last and prior
          # to the output filename
          relegated_opts = supplied_options.delete("relegated_options") || OPTS
          build_options(relegated_opts, @relegated_options)

          # Handle remaining options ('between filenames')
          build_options(supplied_options)

          # Process unrecognized options
          handle_unrecognized_options
        end

        private

        def handle_unrecognized_options
          return unless @unrecognized_options.any?

          opts = @unrecognized_options.map { |opt| "'#{opt}'" }.join("; ")
          errors.add(:options, "unrecognized #{opts}")
        end

        def skip_option?(key)
          key.eql?("")
        end
      end
    end
  end
end
