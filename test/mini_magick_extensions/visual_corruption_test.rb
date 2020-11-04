require_relative '../test_helper'

class VisualCorruptionTest < Minitest::Test
  def setup
  end

  def test_visually_corrupted_image
    image = MiniMagick::Image.new(raster_path('corrupt_pixels.jpg'))
    assert image.visually_corrupt?
  end

  def test_uncorrupted_rgb_image
    image = MiniMagick::Image.new(raster_path('valid_jpg.jpg'))
    refute image.visually_corrupt?
  end

  def test_uncorrupted_cmyk_image
    image = MiniMagick::Image.new(raster_path('cmyk.jpg'))
    refute image.visually_corrupt?
  end

  def test_uncorrupted_grayscale_image
    image = MiniMagick::Image.new(raster_path('grayscale.jpg'))
    refute image.visually_corrupt?
  end
end
