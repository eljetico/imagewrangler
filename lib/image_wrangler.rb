# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'shellwords'
require 'date'
require 'json'

require 'mini_magick'
require 'mini_magick_overrides/info_overrides'
require 'mini_magick_overrides/configuration_overrides'
require 'mini_magick_extensions/convert_tool_options'
require 'mini_magick_extensions/format_families'
require 'mini_magick_extensions/peak_saturation'
require 'mini_magick_extensions/postscript_detection'
require 'mini_magick_extensions/visual_corruption'

module ImageWrangler
  # Use this when referring to resources, eg color profiles
  def self.root
    File.expand_path '..', File.dirname(__FILE__)
  end

  module Transformers
  end

  module Handlers
  end
end

require 'image_wrangler/errors'
require 'image_wrangler/handler'
require 'image_wrangler/handlers/mini_magick_handler'
require 'image_wrangler/image'
require 'image_wrangler/transformers/transformer'
require 'image_wrangler/transformers/mini_magick_transformer'
