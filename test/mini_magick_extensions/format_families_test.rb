# frozen_string_literal: true

require_relative '../test_helper'

class FormatFamiliesTest < Minitest::Test
  # This still doesn't supress PDF warnings encountered here
  MiniMagick.configure(&:quiet_warnings)

  def setup; end

  def test_image_type
    image = MiniMagick::Image.new(raster_path('valid_jpg.jpg'))
    assert_equal 'raster', image.image_type

    image = MiniMagick::Image.new(vector_path('valid.eps'))
    assert_equal 'vector', image.image_type
  end

  def test_valid_raster
    image = MiniMagick::Image.new(raster_path('valid_jpg.jpg'))
    assert image.raster?
    refute image.vector?
  end

  def test_not_a_raster
    image = MiniMagick::Image.new(vector_path('valid.eps'))
    assert image.vector?
    refute image.raster?
  end

  def test_valid_pdf
    image = MiniMagick::Image.new(vector_path('valid.pdf'))
    assert image.vector?
    assert image.postscript?
    refute image.raster?
  end

  def test_valid_webp
    image = MiniMagick::Image.new(raster_path('valid_pam_format.webp'))
    refute image.vector?
    assert image.raster?
  end
end
