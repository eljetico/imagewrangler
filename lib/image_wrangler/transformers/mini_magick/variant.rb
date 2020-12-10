# frozen_string_literal: true

module ImageWrangler
  module Transformers
    module MiniMagick
      #
      # Recipe for rendered component, expected to be a hash eg:
      # {
      #   filepath: '/path/to/my-small-thumb.jpg',
      #   options: {
      #     'geometry' => '100x100',
      #     'gamma' => 0.1,
      #     '+profile' => %w(8BIMTEXT IPTC IPTCTEXT XMP),
      #     'profile' => 'icc:/path/to/profile.icc',
      #     'sharpen' => '1x0.5'
      #    }
      #
      # Note: options can be prefixed with '-' or '+' but hyphens are ignored.
      #
      # Also note: order of operations is important for IM. If color profile
      # conversions are being made, supply the 'profile' option with an array
      # when converting between tricky profiles, eg:
      # {
      #   'profile' => ['transitional.icc', 'rgb.icc']
      # }
      #
      require 'tempfile'

      class Variant < ImageWrangler::Transformers::Variant
        # Order of operations is important for IM convert, so we handle the various
        # groups in the following sequence
        OPTION_GROUP_ORDER = [
          'image_settings',
          'image_operators',
          'image_sequence_operators'
        ]

        def initialize(config = {}, options = {})
          super(config, options)

          @tool = ::MiniMagick::Tool::Convert
          @grouped_options = Hash.new {|hash, key| hash[key] = []}
        end

        def grouped_options
          @grouped_options
        end

        def merged_options
          ordered_options.map {|opt|
            [ opt.to_s, opt.value ]
          }.flatten.compact # remove nil values for argument-less options
        end

        def ordered_options
          return [] if @grouped_options.empty?
          options = []
          OPTION_GROUP_ORDER.each do |og|
            options << @grouped_options[og] unless @grouped_options[og].empty?
          end
          options.flatten
        end

        def process
          tool = @tool.new
          # Use the validated image filepath
          tool << source_image.filepath

          # There are a few ways to do this in MiniMagick, using merge! is
          # the most flexible although requires some care when constructing
          # the options/values
          tool.merge! merged_options

          # Finally, add the output filepath
          tool << filepath

          tool.call do |stdout, stderr, status|
            unless status.zero?
              raise StandardError, stderr
            end

            # Gather data about the resulting file
            inspect_result
          end
        end

        def supplied_options
          @supplied_options ||= @config.fetch(:options, {})
        end

        def unrecognized_options
          @unrecognized_options
        end

        def valid?
          errors.empty?
        end

        def validate!
          validate_empty_options
          validate_options
        end

        def validate_empty_options
          if supplied_options.empty?
            errors.add(:options, 'cannot be empty')
          end
        end

        def validate_options
          @unrecognized_options = []

          supplied_options.each_pair do |key, value|
            next if skip_option?(key)

            unless ImageWrangler::Transformers::MiniMagick::Option.recognized?(key.to_s)
              @unrecognized_options.push(key)
            else
              # Supplied values can be either String, Array or nil
              # Coercing nils to Array doesn't work, so send a special
              # string instead. See Option#value
              Array(value || '_x_').each do |val|
                option = ImageWrangler::Transformers::MiniMagick::Option.new(key.to_s, val)
                @grouped_options[option.option_group].push(option)
              end
            end
          end

          handle_unrecognized_options
        end

        private

        def handle_unrecognized_options
          if @unrecognized_options.any?
            stringified = @unrecognized_options.map {|opt| "'#{opt}'" }.join('; ')
            errors.add(:options, "unrecognized #{stringified}")
          end
        end

        def skip_option?(key)
          key.eql?('')
        end
      end
    end
  end
end
