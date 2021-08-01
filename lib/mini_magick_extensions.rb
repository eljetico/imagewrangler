# frozen_string_literal: true

module MiniMagick
  OPTS = {}.freeze
  EMPTY_ARRAY = [].freeze
end

require "mini_magick_extensions/convert_tool_options"
require "mini_magick_extensions/format_families"
require "mini_magick_extensions/peak_saturation"
require "mini_magick_extensions/postscript_detection"
require "mini_magick_extensions/visual_corruption"
