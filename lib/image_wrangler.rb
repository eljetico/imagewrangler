# frozen_string_literal: true

require "open3"
require "securerandom"
require "shellwords"
require "date"
require "json"

require "mini_exiftool"
require "mini_magick"

require_relative "mini_exiftool_overrides/all_overrides"

# Top level module
module ImageWrangler
  OPTS = {}.freeze
  EMPTY_ARRAY = [].freeze
  EXIFTOOL_VERSION = "12.29"

  # Use this when referring to resources, eg color profiles
  class << self
    def colorize(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
    end

    def root
      File.expand_path "..", File.dirname(__FILE__)
    end

    def exiftool_lib
      @exiftool_lib ||= File.join(root, "vendor", "Image-ExifTool-#{EXIFTOOL_VERSION}")
    end

    def url?(filepath)
      filepath.to_s.match(/\Ahttps?:/i).to_a.any?
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

require_relative "mini_magick_overrides/configuration_overrides"
require_relative "mini_magick_overrides/info_overrides"
require_relative "mini_magick_extensions/convert_tool_options"
require_relative "mini_magick_extensions/format_families"
require_relative "mini_magick_extensions/peak_saturation"
require_relative "mini_magick_extensions/postscript_detection"
require_relative "mini_magick_extensions/visual_corruption"
require_relative "image_wrangler/c2pa"
require_relative "image_wrangler/dimensions"
require_relative "image_wrangler/errors"
require_relative "image_wrangler/file_attributes"
require_relative "image_wrangler/handler"
require_relative "image_wrangler/handlers/mini_magick_handler"
require_relative "image_wrangler/logger"
require_relative "image_wrangler/metadata"
require_relative "image_wrangler/openable"
require_relative "image_wrangler/profiles"
require_relative "image_wrangler/scaling_helper"
require_relative "image_wrangler/transformers/transformer"
require_relative "image_wrangler/transformers/mini_magick_transformer"
require_relative "image_wrangler/image"
