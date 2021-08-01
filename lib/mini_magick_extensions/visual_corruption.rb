# frozen_string_literal: true

module MiniMagick
  # Check for visual corruption of supplied image
  class Image
    RGB_VALUE_REGEX = Regexp.new('\((\d{1,3}),(\d{1,3}),(\d{1,3})\)')

    def histogram_for_sample(options = MiniMagick::OPTS)
      opts = {
        gravity: "SouthEast",
        crop: "20%x1%"
      }.merge(options)

      run_command(
        "convert",
        path,
        "-gravity",
        opts[:gravity],
        "-crop",
        opts[:crop],
        "-format",
        "%c",
        "-depth", 8,
        "histogram:info:"
      ).split("\n").compact
    end

    def rgb_values_from_histogram(hist)
      return [] if hist.length > 1

      (hist[0].scan(RGB_VALUE_REGEX).flatten || MiniMagick::EMPTY_ARRAY).uniq
    end

    # User can pass in full options such as
    # {
    #    max_gray: 180,
    #    min_gray: 120,
    #    crop: "30%x2%",
    #    gravity: "SouthEast"
    # }
    def visually_corrupt?(opts = MiniMagick::OPTS)
      return false unless raster?

      test_opts = {max_gray: 180, min_gray: 120}.merge(opts)

      rgb = rgb_values_from_histogram(histogram_for_sample(test_opts))

      return false if rgb.empty? || (rgb.length > 1)

      (test_opts[:min_gray]..test_opts[:max_gray]).cover?(rgb[0].to_i)
    end
  end
end
