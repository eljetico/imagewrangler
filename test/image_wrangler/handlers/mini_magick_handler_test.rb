# frozen_string_literal: true

# frozen_string_literal: true

require_relative '../../test_helper'
require 'image_wrangler/handlers/mini_magick_handler'

class MiniMagickHandlerTest < Minitest::Test
  def setup
    @handler = ImageWrangler::Handlers::MiniMagickHandler
    @subject = @handler.new
  end

  def test_initialization_with_local_file
    filepath = raster_path('valid_jpg.jpg')
    assert @subject.load_image(filepath)
  end

  def test_initialization_with_missing_file
    filepath = raster_path('missing.jpg')

    assert_raises ImageWrangler::MissingImageError do
      @subject.load_image(filepath)
    end
  end

  def test_initialize_with_corrupt_local_file
    assert_raises ImageWrangler::CorruptImageError do
      @subject.load_image(raster_path('corrupt_premature_end.jpg'))
    end
  end

  def test_initialize_with_corrupt_remote_file
    stub_request(:get, "https://example.com/corrupt.jpg")
      .to_return(body: File.read(raster_path('corrupt_premature_end.jpg')))

    assert_raises ImageWrangler::CorruptImageError do
      @subject.load_image("https://example.com/corrupt.jpg")
    end
  end

  def test_basic_initialization_with_missing_url
    stub_request(:get, "https://example.com/image.jpg")
      .to_return(status: 404, body: "Not found")

    assert_raises ImageWrangler::RemoteImageError do
      @subject.load_image("https://example.com/image.jpg")
    end
  end

  def test_attributes_retrieval_local_file
    assert @subject.load_image(raster_path('valid_jpg.jpg'))

    assert_equal 'image/jpeg', @subject.mime_type
    assert_equal 'abb4755aff726b0c4ac77c7be07b4776', @subject.checksum
    assert_equal 1000, @subject.height
    assert_equal 697, @subject.width
    assert_equal 'JPEG', @subject.format
    refute @subject.visually_corrupt?
  end

  def test_attributes_retrieval_remote_file
    stub_request(:get, "https://example.com/image.jpg")
      .to_return(body: File.read(raster_path('cmyk.jpg')))

    assert @subject.load_image("https://example.com/image.jpg")

    assert_equal 'image/jpeg', @subject.mime_type
    assert_equal 'CMYK', @subject.colorspace
    assert_equal '.jpg', @subject.extension
    assert @subject.valid_extension?
    assert_equal '638595b250d6afdf8f62dcd299da1ad0', @subject.checksum
    refute @subject.visually_corrupt?
  end

  def test_iptc_create_date
    assert @subject.load_image(raster_path('grayscale.jpg'))
    refute @subject.iptc_date_created.nil?
    assert_equal 1970, @subject.iptc_date_created.year
  end

  def test_camera_make_and_model
    assert @subject.load_image(raster_path('clipping_path.jpg'))
    assert_equal 'Canon', @subject.camera_make
    assert_equal 'Canon EOS 5D', @subject.camera_model
  end

  def test_raster_detection
    @subject.load_image(raster_path('grayscale.jpg'))
    assert @subject.raster?
    refute @subject.vector?
  end

  def test_vector_detection
    @subject.load_image(vector_path('valid.eps'))
    assert @subject.vector?
    assert @subject.postscript?
    refute @subject.raster?
  end

  # def test_vector_rescale_factor
  #   @subject.load_image(vector_path('valid.eps'))
  #   assert_equal 12.5, @subject.vector_rescale_factor
  # end
end
