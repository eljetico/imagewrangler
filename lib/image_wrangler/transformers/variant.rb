# frozen_string_literal: true

module ImageWrangler
  # Transformers process images
  module Transformers
    #
    # Config for rendered component, expected to be a hash eg:
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
    require "tempfile"

    # Handler to configure and process required variant using chosen
    # cli via concrete class, eg ::Transformers::MiniMagick::Variant
    # which build command to pass to MiniMagick::Convert
    #
    # `config` should contain requirements for generated file
    # `options` should override errors handler etc
    class Variant
      attr_accessor :attributes,
        :command,
        :checksum,
        :height,
        :image_type,
        :mime_type,
        :mtime,
        :size,
        :source_image,
        :width

      def initialize(config = OPTS, options = OPTS)
        @source_image = nil
        @config = OPTS.merge(config) # we have no defaults, but this may change
        @options = {errors: ImageWrangler::Errors.new}.merge(options)
      end

      def errors
        @errors ||= @options[:errors]
      end

      def filename
        @filename ||= File.basename(filepath)
      end

      # Output filepath, as supplied, or a /tmp file
      def filepath
        @filepath ||= @config[:filepath] || generate_tmp_filepath
      end
      alias_method :file_path, :filepath

      def filesize
        @size
      end

      def inspect_result
        image = ImageWrangler::Image.new(filepath)
        unless image.errors.empty?
          errors.add(:result, image.errors.to_s)
          return nil
        end
        assign_output_attributes(image)
      rescue => e
        errors.add(:result, e.full_message)
      end

      # Create/generate the variant.
      # Errors should be added to errors handler and return
      # by calling `valid?`
      def process(options = OPTS)
        raise NotImplementedError
      end

      def valid?
        errors.empty?
      end

      def validate!
        raise NotImplementedError
      end

      private

      def assign_output_attributes(image)
        @checksum = image.checksum
        @mtime = image.mtime
        @height = image.height
        @image_type = image.image_type
        @mime_type = image.mime_type
        @size = image.size
        @width = image.width
      end

      def generate_filename
        @config.fetch(:filename, "image_wrangler.#{random_token}")
      end

      def generate_tmp_filepath
        File.join("/", "tmp", generate_filename)
      end

      def random_token
        rand(36**8).to_s(36)
      end
    end
  end
end
