# frozen_string_literal: true

module MiniMagick
  # Check for visual corruption of supplied image
  class Image
    SATURATION_VALUE_REGEX = Regexp.new(
      'avg=(?<avg_sat>[\d\.]+)\speak=(?<peak_sat>[\d\.]+)'
    ).freeze

    def peak_saturation
      @peak_saturation ||= begin
        result = run_command(
          "convert",
          path,
          "-colorspace", "HCL",
          "-format", '"%M avg=%[fx:mean.g] peak=%[fx:maxima.g]\n"',
          "info:"
        )

        match = result.match(SATURATION_VALUE_REGEX)
        raise if match.nil?

        match[:peak_sat].to_f
      end
    rescue => e
      message = "failed extracting peak_saturation: #{result}, #{e.message}"
      raise MiniMagick::Error, message
    end
  end
end
