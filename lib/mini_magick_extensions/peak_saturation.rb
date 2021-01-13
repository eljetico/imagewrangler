# frozen_string_literal: true

module MiniMagick
  # Check for visual corruption of supplied image
  class Image
    SATURATION_VALUE_REGEX = Regexp.new(
      'avg=(?<avg_sat>[\d\.]+)\speak=(?<peak_sat>[\d\.]+)'
    )

    def peak_saturation
      @peak_saturation ||= begin
        # rubocop:disable Layout/LineLength
        result = run_command('convert', path, '-colorspace', 'HCL', '-format', '"%M avg=%[fx:mean.g] peak=%[fx:maxima.g]\n"', 'info:')
        # rubocop:enable Layout/LineLength

        match = result.match(SATURATION_VALUE_REGEX)
        raise if match.nil?

        match[:peak_sat].to_f
      end
    rescue StandardError => e
      message = "failed extracting peak_saturation: #{result}, #{e.message}"
      raise MiniMagick::Error, message
    end
  end
end
