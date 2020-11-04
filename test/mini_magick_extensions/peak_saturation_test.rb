# frozen_string_literal: true

require_relative '../test_helper'
require 'image_wrangler'

# rubocop:disable Metrics/ClassLength
class PeakSaturationTest < Minitest::Test
  def setup
  end

  def test_value_from_grayscale_image
    image = MiniMagick::Image.new(raster_path('grayscale.jpg'))
    assert_equal 0, image.peak_saturation
  end

  def test_value_from_color_image
    image = MiniMagick::Image.new(raster_path('valid_lo_res.jpg'))
    assert_equal 0.984314, image.peak_saturation
  end
end
