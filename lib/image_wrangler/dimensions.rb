# frozen_string_literal: true

module ImageWrangler
  class Dimensions
    attr_accessor :width, :height

    def initialize(width, height)
      @width = width
      @height = height
    end

    def to_a
      [width, height]
    end

    def to_h
      {width: width, height: height}
    end

    def to_s
      "#{width}x#{height}"
    end
  end
end
