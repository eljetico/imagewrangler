# frozen_string_literal: true

require "timeliness"
require_relative "../test_helper"

class ImageTest < Minitest::Test
  def setup
  end

  def test_basic_attributes_raster
    image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))

    assert_equal 1000, image.height
    assert_equal 697, image.width
    assert_equal 0.697, image.megapixels
    assert_equal 697000, image.pixelarea
    assert_equal "0.7mp", image.megapixels_humanized
    assert_equal "RGB", image.colorspace
    assert_equal 119_333, image.filesize
    assert_equal "abb4755aff726b0c4ac77c7be07b4776", image.checksum
    assert_equal ".jpg", image.preferred_extension
    assert_predicate image, :raster?
    refute_predicate image, :vector?
  end

  def test_scaling_included
    image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
    scaling = image.dimensions_for_target_pixel_area(3_000_000)
    assert_equal 1447, scaling.width
    assert_equal 2076, scaling.height
  end

  def test_identifies_cloaked_file
    image = ImageWrangler::Image.new(raster_path("png_as_jpg.jpg"))

    assert_equal ".jpg", image.extname
    assert_equal ".png", image.preferred_extension
  end

  def test_preferred_extension_for_jpeg_files
    image = ImageWrangler::Image.new(raster_path("valid_jpg.jpeg"))
    assert_equal ".jpg", image.preferred_extension
  end

  def test_basic_attributes_vector
    image = ImageWrangler::Image.new(vector_path("valid.eps"))

    assert_equal 503, image.height
    assert_equal 990, image.width
    assert_equal "CMYK", image.colorspace
    assert_equal 1_425_512, image.filesize
    assert_equal "21de1f0f359eb03f0224f4bcc00384fe", image.checksum
    refute_predicate image, :raster?
    assert_predicate image, :vector?
  end

  def test_validate_with_raster
    wrangler = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))

    wrangler.validate do |img|
      img.errors.add(:colorspace, "must be CMYK") unless img.colorspace.eql?("CMYK")
    end

    assert_includes wrangler.errors, :colorspace
    assert_equal ["colorspace must be CMYK"], wrangler.errors.full_messages
  end

  def test_validate_with_vector
    wrangler = ImageWrangler::Image.new(vector_path("not_valid_v3.1.eps"))

    wrangler.validate do |img|
      ver = img.postscript_version
      img.errors.add(:postscript_version, "must be <= 3.0") unless ver <= 3.0
    end

    assert_includes wrangler.errors, :postscript_version

    assert_equal ["postscript_version must be <= 3.0"], wrangler.errors.full_messages
  end

  def test_transformer_defaults
    wrangler = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
    subject = wrangler.transformer([])
    assert subject.is_a?(ImageWrangler::Transformers::MiniMagick::Transformer)
    refute subject.valid? # component list cannot be empty
  end

  def test_mtime_with_local_file
    wrangler = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
    subject = wrangler.mtime
    assert(subject.is_a?(Time))
    assert(subject < Time.now)
  end

  def test_mtime_with_remote_file
    filepath = raster_path("valid_jpg.jpg")

    stub_request(:get, "https://example.com/image.jpg")
      .to_return(
        {
          body: File.read(filepath),
          headers: {
            "Date" => "Thu, 01 Apr 2021 12:09:35 GMT",
            "Last-Modified" => "Thu, 18 Mar 2021 22:34:32 GMT",
            "Etag" => '"a0a368ca9cffcac6bdc0bcf69138dd0c-201"',
            "Accept-Ranges" => "bytes",
            "Content-Type" => "image/jpeg",
            "Content-Length" => File.size(filepath)
          }
        }
      )

    wrangler = ImageWrangler::Image.new("https://example.com/image.jpg")
    subject = wrangler.mtime

    assert(subject.is_a?(Time))
    assert(subject < Time.now)
  end
end
