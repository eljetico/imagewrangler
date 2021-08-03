# frozen_string_literal: true

require "open3"
require "securerandom"
require "shellwords"
require "date"
require "json"

require "mini_exiftool"
require "mini_magick"

# Top level module
module ImageWrangler
  OPTS = {}.freeze
  EMPTY_ARRAY = [].freeze
  EXIFTOOL_VERSION = "12.29"

  # Use this when referring to resources, eg color profiles
  class << self
    def root
      File.expand_path "..", File.dirname(__FILE__)
    end

    def exiftool_lib
      @exiftool_lib ||= File.join(root, "vendor", "Image-ExifTool-#{EXIFTOOL_VERSION}")
    end
  end

  # Transformers to process images
  module Transformers
  end

  # Assert specific image file handlers: default is MiniMagick
  module Handlers
  end

  # Container for various ICC color profile handlers
  module Profiles
  end

  # Ensure we're using the correct Exiftool executable
  # Pstore is committed to repo/image and specified here to prevent Exiftool
  # from building tags on first invocation
  MiniExiftool.command = File.join(exiftool_lib, "exiftool")
  MiniExiftool.pstore_dir = File.join(exiftool_lib, "pstore")
end

module MiniMagick
  OPTS = {}.freeze
  EMPTY_ARRAY = [].freeze
end

require "mini_magick_overrides/info_overrides"
require "mini_magick_overrides/configuration_overrides"
require "mini_magick_extensions/convert_tool_options"
require "mini_magick_extensions/format_families"
require "mini_magick_extensions/peak_saturation"
require "mini_magick_extensions/postscript_detection"
require "mini_magick_extensions/visual_corruption"
require "image_wrangler/dimensions"
require "image_wrangler/errors"
require "image_wrangler/handler"
require "image_wrangler/handlers/mini_magick_handler"
require "image_wrangler/logger"
require "image_wrangler/metadata"
require "image_wrangler/profiles"
require "image_wrangler/scaling_helper"
require "image_wrangler/transformers/transformer"
require "image_wrangler/transformers/mini_magick_transformer"
require "image_wrangler/image"
