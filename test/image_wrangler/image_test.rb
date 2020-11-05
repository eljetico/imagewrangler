# frozen_string_literal: true

require_relative '../test_helper'
require 'image_wrangler'

class ImageTest < Minitest::Test
  def setup
  end

  def test_basic_attributes
    image = ImageWrangler::Image.new(raster_path('valid_jpg.jpg'))

    assert_equal 1000, image.height
    assert_equal 697, image.width
    assert_equal 'RGB', image.colorspace
    assert_equal 119333, image.filesize
    assert_equal 'abb4755aff726b0c4ac77c7be07b4776', image.checksum
    assert_predicate image, :raster?
    refute_predicate image, :vector?
  end

  def test_validate
    wrangler = ImageWrangler::Image.new(raster_path('valid_jpg.jpg'))

    wrangler.validate do |img|
      img.errors.add(:colorspace, 'must be CMYK') unless img.colorspace.eql?('CMYK')
    end

    assert_includes wrangler.errors, :colorspace
    assert_equal ['colorspace must be CMYK'], wrangler.errors.full_messages
  end
end
