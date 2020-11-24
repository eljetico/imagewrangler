# frozen_string_literal: true

module ImageWrangler
  class Handlers::MiniMagickHandler < Handler
    DEFAULT_TIMEOUT = 10
    DEFAULT_QUIET_WARNINGS = true

    def initialize(**options)
      opts = {
        magick_timeout: DEFAULT_TIMEOUT,
        quiet_warnings: DEFAULT_QUIET_WARNINGS #,
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
      @bit_depth ||= nil_or_integer(raw_attribute('bit-depth'))
    end
    alias bitdepth bit_depth

    def black_and_white?
      return false if peak_saturation.nil?
      peak_saturation <= GRAYSCALE_PEAK_SATURATION_THRESHOLD
    end

    def camera_make
      @camera_make ||= nil_or_string(raw_attribute('EXIF:Make'))
    end

    def camera_model
      @camera_model ||= nil_or_string(raw_attribute('EXIF:Model'))
    end

    # Note `identify -format "%[channels]"` returns colorspace (lowercased)
    # with current IM version so we use bruteforce method
    def channel_count
      @channel_count ||= begin
        self.colorspace.match(/\Agray/i) ? 1 : self.colorspace.length
      end
    end
    alias channels channel_count

    def checksum
      @checksum ||= begin
        md5 = Digest::MD5.file @magick.path
        md5.hexdigest
      end
    end

    def color?
      return false if peak_saturation.nil?
      peak_saturation > GRAYSCALE_PEAK_SATURATION_THRESHOLD
    end

    def colorspace
      @colorspace ||= extract_color_space
    end

    def create_date
      extract_create_date
    end
    alias date_created create_date
    alias shoot_date create_date

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
        path = @magick.path || ''
        nil_or_string(File.extname(path))
      end
    end
    alias_method :ext, :extname
    alias_method :extension, :extname

    # TODO: need to handle URLs here too
    # def filename
    #   @filename ||= begin
    #     path = @magick.path || ''
    #     nil_or_string(File.basename(path))
    #   end
    # end

    def format
      attribute('type') || 'UNKNOWN'
    end
    alias file_format format

    def height
      @height ||= (nil_or_integer(attribute('height')) || 0)
    end

    def image_sequence?
      pages.length > 1
    end

    def width
      @width ||= (nil_or_integer(attribute('width')) || 0)
    end

    def loaded?
      @loaded
    end

    def filepath
      @filepath
    end
    alias file_path filepath

    def filesize
      @filesize ||= stat.size
    end

    def load_image(filepath)
      @loaded = false
      @filepath = filepath

      # MiniMagick.logger.level = Logger::DEBUG
      @magick = MiniMagick::Image.open(@filepath)

      # Force IM to trigger read error
      # This is an arbitrary key, but one which triggers the error
      # Another option would be to persist output of @magick.data
      # but this operation takes some time, calling 'identify -verbose'
      @magick.colorspace
      @loaded = @magick.valid?

      @loaded
    rescue Errno::ENOENT => error
      raise ImageWrangler::Error, "not found at '#{filepath}'"
    rescue MiniMagick::Error => error
      handle_mini_magick_error(error)
    rescue MiniMagick::Invalid => error
      handle_mini_magick_invalid(error)
    rescue OpenURI::HTTPError => error
      raise ImageWrangler::Error, error.message
    end

    def iptc_date_created
      @iptc_date_created ||= extract_iptc_date_created
    end

    def orientation
      @orientation ||= nil_or_string(raw_attribute('orientation'))
    end

    def paths
      @paths ||= extract_embedded_paths
    end

    def paths?
      !paths.nil?
    end

    def peak_saturation
      @peak_saturation ||= @analyzer.peak_saturation
    rescue StandardError => e
      # Should log this message somewhere
      return nil
    end

    def quality
      @quality ||= nil_or_integer(raw_attribute('Q'))
    end

    def size
      @size ||= nil_or_integer(attribute('size'))
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
      color_mode = raw_attribute('colorspace')
      return nil if color_mode.nil?

      normalized_color_space(color_mode)
    end

    # Prefer IPTC as can be asserted by creator
    def extract_create_date
      iptc_date_created || exif_date_time_original || exif_date_time_digitized
    end

    def extract_embedded_paths
      nil_or_string(raw_attribute('8BIM:2000,2999'))
    end

    def extract_exif_date_time_original
      value = nil_or_string(raw_attribute('EXIF:DateTimeOriginal'))
      parse_date(value, '%Y:%m:%d %H:%M:%S')
    rescue StandardError => e
      @context.errors.add("Error parsing EXIF:DateTimeOriginal #{e.message}")
      return nil
    end

    def extract_exif_date_time_digitized
      value = nil_or_string(raw_attribute('EXIF:DateTimeDigitized'))
      parse_date(value, '%Y:%m:%d %H:%M:%S')
    rescue StandardError => e
      @context.errors.add("Error parsing EXIF:DateTimeOriginal #{e.message}")
      return nil
    end

    def extract_iptc_date_created
      value = nil_or_string(raw_attribute('IPTC:2:55'))
      parse_date(value, '%Y%m%d')
    rescue StandardError => e
      @context.errors.add("Error parsing IPTC:2:55 #{e.message}")
      nil
    end

    def handle_mini_magick_error(error)
      example = error.message.split("\n")[1]

      if example.match(/premature end/i)
        raise ImageWrangler::Error, 'corrupted file'
      elsif example.match(/empty input file/i)
        raise ImageWrangler::Error, 'empty file'
      end

      raise
    end

    def handle_mini_magick_invalid(error)
      handle_mini_magick_error(error)
    end

    def raw_attribute(attr_key)
      v = loaded? ? @magick["%[#{attr_key}]"] : ''
      v.match(/^$/) ? nil : v
    end

    # TODO: enable set_log_level here
    def configure_handler(options)
      # MiniMagick.logger.level = Logger::DEBUG
      MiniMagick.configure do |config|
        config.timeout = options.fetch(:magick_timeout)
        config.quiet_warnings = options.fetch(:quiet_warnings)
      end

      # @errors = options.fetch(:errors)
    end
  end
end
