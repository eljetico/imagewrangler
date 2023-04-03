# frozen_string_literal: true

module ImageWrangler
  module Handlers
    # MiniMagick-specific handler
    class MiniMagickHandler < Handler
      DEFAULT_QUIET_WARNINGS = true

      def initialize(**options)
        opts = {
          quiet_warnings: DEFAULT_QUIET_WARNINGS
        }.merge(options)

        super(opts)
      end

      def method_missing(method, *args, &block)
        if @magick.respond_to?(method)
          @magick.send(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        @magick.respond_to?(method) || super
      end

      def bit_depth
        @bit_depth ||= nil_or_integer(raw_attribute("bit-depth"))
      end
      alias_method :bitdepth, :bit_depth

      def black_and_white?
        return false if peak_saturation.nil?

        peak_saturation <= GRAYSCALE_PEAK_SATURATION_THRESHOLD
      end

      def camera_make
        @camera_make ||= nil_or_string(raw_attribute("EXIF:Make"))
      end

      def camera_model
        @camera_model ||= nil_or_string(raw_attribute("EXIF:Model"))
      end

      # Note `identify -format "%[channels]"` returns colorspace (lowercased)
      # with current IM version so we use bruteforce method
      def channel_count
        @channel_count ||= colorspace =~ /\Agray/i ? 1 : colorspace.length
      end
      alias_method :channels, :channel_count

      def checksum(opts = OPTS)
        @checksum ||= begin
          md5 = Digest::MD5.file @magick.path
          md5.hexdigest
        end
      end

      def color?
        return false if peak_saturation.nil?

        peak_saturation > GRAYSCALE_PEAK_SATURATION_THRESHOLD
      end

      def color_managed?
        !icc_name.nil?
      end

      def colorspace
        @colorspace ||= extract_color_space
      end

      def create_date
        extract_create_date
      end
      alias_method :date_created, :create_date
      alias_method :shoot_date, :create_date

      def exif_date_time_original
        @exif_date_time_original ||= extract_exif_date_time_original
      end

      def exif_date_time_digitized
        @exif_date_time_digitized ||= extract_exif_date_time_digitized
      end

      # TODO: persist ext from MiniMagick::Image.create
      # Need to handle URLs/blobs too
      def extname
        @extname ||= begin
          path = @magick.path || ""
          nil_or_string(File.extname(path))
        end
      end
      alias_method :ext, :extname
      alias_method :extension, :extname

      def format
        attribute("type") || "UNKNOWN"
      end
      alias_method :file_format, :format

      def height
        @height ||= (nil_or_integer(attribute("height")) || 0)
      end

      def icc_name
        @icc_name ||= nil_or_string(raw_attribute("ICC:model"))
      end

      def image_sequence?
        pages.length > 1
      end

      def loaded_path
        @magick.path
      end

      def width
        @width ||= (nil_or_integer(attribute("width")) || 0)
      end

      def loaded?
        @loaded
      end

      def file_path
        filepath
      end

      def filesize(opts = OPTS)
        @filesize ||= stat.size
      end

      def load_image(path_or_url, options = OPTS)
        openable = ImageWrangler::Openable.for(path_or_url, options)
        @loaded = false
        @magick = MiniMagick::Image.read(openable.stream, openable.extension)

        # Force IM to trigger read error
        # This is an arbitrary key, but one which triggers the error
        # Another option would be to persist output of @magick.data
        # but this operation takes some time, calling 'identify -verbose'
        @magick.colorspace
        @loaded = @magick.valid?

        @loaded
      rescue ImageWrangler::Error => _e
        raise
      rescue MiniMagick::Error => e
        handle_mini_magick_error(e)
      rescue MiniMagick::Invalid => e
        handle_mini_magick_invalid(e)
      rescue OpenURI::HTTPError => e
        raise ImageWrangler::Error, e.message
      ensure
        openable&.stream&.close
      end

      def iptc_date_created
        @iptc_date_created ||= extract_iptc_date_created
      end

      #
      # MiniMagick messes up mime type by prefixing detected format string
      # with "image", eg "image/pdf".
      #
      # IM retrieves the correct? value, so we can access this via the `data`
      # method, which calls `convert json:`
      #
      # IM can often return invalid JSON from this call, so we have to fall
      # back to the deprecated `details` method which runs `identify -verbose`
      #
      # Options: use MIME::Types to interrogate the file.
      #
      # https://github.com/minimagick/minimagick/blob/master/lib/mini_magick/image/info.rb
      #
      # rubocop:disable Style/RedundantBegin
      def mime_type
        @mime_type ||= begin
          ["mimeType", "Mime type"].map { |k|
            raw_magick_data.fetch(k, nil)
          }.compact.first || @magick.mime_type
        end
      end
      # rubocop:enable Style/RedundantBegin

      def orientation
        @orientation ||= nil_or_string(raw_attribute("orientation"))
      end

      def paths
        @paths ||= extract_embedded_paths
      end

      def paths?
        !paths.nil?
      end

      def peak_saturation
        @peak_saturation ||= @analyzer.peak_saturation
      rescue
        # Should log the error somewhere
        nil
      end

      # TODO: handle URLs!
      def preferred_extension
        @preferred_extension ||= @magick.valid_extensions[0]
      end

      def quality
        @quality ||= nil_or_integer(raw_attribute("Q"))
      end

      def size
        @size ||= nil_or_integer(attribute("size"))
      end

      def stat
        @stat ||= File.stat(@magick.path)
      end

      def valid_extension?
        return false if extname.nil?

        @magick.valid_extensions.include?(extname.downcase)
      end

      private

      def attribute(attr)
        loaded? ? @magick.send(attr.to_sym) : nil
      end

      def extract_color_space
        # TODO: check MiniMagick handling of image.colorspace 'method'
        color_mode = raw_attribute("colorspace")
        return nil if color_mode.nil?

        normalized_color_space(color_mode)
      end

      # Prefer IPTC as can be asserted by creator
      def extract_create_date
        iptc_date_created || exif_date_time_original || exif_date_time_digitized
      end

      def extract_embedded_paths
        nil_or_string(raw_attribute("8BIM:2000,2999"))
      end

      def extract_exif_date_time_original
        value = nil_or_string(raw_attribute("EXIF:DateTimeOriginal"))
        parse_date(value, "%Y:%m:%d %H:%M:%S")
      rescue => e
        @context.errors.add("Error parsing EXIF:DateTimeOriginal #{e.message}")
        nil
      end

      def extract_exif_date_time_digitized
        value = nil_or_string(raw_attribute("EXIF:DateTimeDigitized"))
        parse_date(value, "%Y:%m:%d %H:%M:%S")
      rescue => e
        @context.errors.add("Error parsing EXIF:DateTimeOriginal #{e.message}")
        nil
      end

      def extract_iptc_date_created
        value = nil_or_string(raw_attribute("IPTC:2:55"))
        parse_date(value, "%Y%m%d")
      rescue => e
        @context.errors.add("Error parsing IPTC:2:55 #{e.message}")
        nil
      end

      def handle_mini_magick_error(error)
        example = error.message.split("\n")[1]

        raise ImageWrangler::Error, "corrupted file" if example =~ /premature end/i
        raise ImageWrangler::Error, "empty file" if example =~ /empty input file/i

        # In calling code, use err.cause to access nested exception
        raise ImageWrangler::Error, "MiniMagick error #{error}"
      end

      def handle_mini_magick_invalid(error)
        handle_mini_magick_error(error)
      end

      def raw_attribute(attr_key)
        v = loaded? ? @magick["%[#{attr_key}]"] : ""
        v.eql?("") ? nil : v
      end

      # TODO: enable set_log_level here
      def configure_handler(options)
        # MiniMagick.logger.level = Logger::DEBUG
        MiniMagick.configure do |config|
          config.quiet_warnings = options.fetch(:quiet_warnings)
        end
      end

      private

      def extract_raw_data
        @magick.data
      rescue JSON::ParserError => _
        warn "JSON parser error, dropping to deprecated MiniMagick.details method"
        @magick.details
      rescue
        warn "Unhandled raw data error"
        {}
      end

      def raw_magick_data
        @raw_magick_data ||= extract_raw_data
      end
    end
  end
end
