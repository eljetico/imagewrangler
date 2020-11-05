# frozen_string_literal: true

module ImageWrangler
  class Handler
    GRAYSCALE_PEAK_SATURATION_THRESHOLD = 0.15 # ESP value

    def initialize(**options)
      opts = {
      }.merge(options)

      configure_handler(opts)
    end

    def megapixels
      width * height
    end

    private

    def nil_or_integer(value = nil)
      value.nil? ? nil : value.to_i
    end

    def nil_or_string(value = nil)
      value.nil? ? nil : value.to_s
    end

    def normalized_color_space(color_mode = nil)
      return nil if color_mode.nil?

      cleaned_color_space = color_mode.strip
      color_space = cleaned_color_space.eql?('Gray') ? 'Grayscale' : cleaned_color_space
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
