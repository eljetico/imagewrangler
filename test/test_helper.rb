# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")

require "minitest/autorun"
require "minitest/reporters"
# require "webmock/minitest"

require "image_wrangler"
require "http"

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

begin
  HTTP.get(ENV["httpbin"]).to_s
rescue HTTP::ConnectionError
  puts <<~WARNING
    The httpbin server is not running on port 80, which is required for tests.
  WARNING
  exit 1
end

def clear_outfiles
  Dir.glob("/tmp/#{outfile_key}.*").each do |file|
    File.unlink(file)
  end
end

def config_path(filename)
  File.join(fixtures_path, "configurations", filename)
end

def fixtures_path
  "#{File.dirname(__FILE__)}/fixtures"
end

def ghostscipt_installed?
  MiniMagick.delegate_installed?("gs")
end

def httpbin
  ENV["httpbin"]
end

def outfile_key
  "imagewrangler"
end

def raster_path(filename)
  File.join(fixtures_path, "raster", filename)
end

def vector_path(filename)
  File.join(fixtures_path, "vector", filename)
end

def nonimage_path(filename)
  File.join(fixtures_path, "non_image", filename)
end
