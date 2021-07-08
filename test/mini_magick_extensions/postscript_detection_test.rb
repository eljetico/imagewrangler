# frozen_string_literal: true

require_relative "../test_helper"
require "image_wrangler"

class PostscriptDetectionTest < Minitest::Test
  def setup
  end

  def test_postscript_version
    image = MiniMagick::Image.new(vector_path("valid.eps"))
    assert_equal 3.0, image.postscript_version

    image = MiniMagick::Image.new(vector_path("not_valid_v3.1.eps"))
    assert_equal 3.1, image.postscript_version

    image = MiniMagick::Image.new(vector_path("valid_2.eps"))
    assert_equal 3.1, image.postscript_version
  end

  def test_resize_density
    target_pixels = 4 * 1_000_000
    image = MiniMagick::Image.new(vector_path("valid.eps"))
    assert_equal 207, image.postscript_resize_density(target_pixels)
  end

  def test_resize_density_raster_file
    image = MiniMagick::Image.new(raster_path("grayscale.jpg"))
    assert_nil image.postscript_resize_density(2000)
  end
end
