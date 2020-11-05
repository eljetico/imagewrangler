# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'

require 'image_wrangler'

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

def fixtures_path
  "#{File.dirname(__FILE__)}/fixtures"
end

def ghostscipt_installed?
  MiniMagick.delegate_installed?('gs')
end

def raster_path(filename)
  File.join(fixtures_path, 'raster', filename)
end

def vector_path(filename)
  File.join(fixtures_path, 'vector', filename)
end

def nonimage_path(filename)
  File.join(fixtures_path, 'non_image', filename)
end
