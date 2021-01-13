# frozen_string_literal: true

module ImageWrangler
  class Handler
    GRAYSCALE_PEAK_SATURATION_THRESHOLD = 0.15 # ESP value

    attr_accessor :filepath

    def initialize(**options)
      opts = {
      }.merge(options)

      configure_handler(opts)
    end

    def megapixels
      @megapixels ||= ((width * height).to_f / 1_000_000)
    end
    alias mp megapixels

    def megapixels_humanized
      @megapixels_humanized ||= "#{megapixels.round(1)}mp"
    end
    alias mp_h megapixels_humanized

    private

    def nil_or_integer(value = nil)
      value.nil? ? nil : value.to_i
    end

    def nil_or_string(value = nil)
      value.nil? ? nil : value.to_s
    end

    def normalized_color_space(color_mode = nil)
      return nil if color_mode.nil?

      clean_space = color_mode.strip
      color_space = clean_space.eql?('Gray') ? 'Grayscale' : clean_space
      ['srgb'].include?(color_space.downcase) ? 'RGB' : color_space
    end

    def parse_date(dayte, date_format = '%Y:%m:%d %H:%M:%S')
      return nil if dayte.nil?
      return dayte if dayte.is_a? Time

      Date.strptime(dayte, date_format).to_time
    rescue StandardError => _e
      nil
    end
  end
end
