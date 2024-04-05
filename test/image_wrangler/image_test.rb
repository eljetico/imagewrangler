# frozen_string_literal: true

require "timeliness"
require_relative "../test_helper"

class ImageTest < Minitest::Test
  def setup
  end

  def test_basic_attributes_raster
    image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))

    assert_equal "image/jpeg", image.mime_type
    assert_equal "808-185", image.get_tag("title")
    refute_empty image.get_all_tags
    assert_equal 1000, image.height
    assert_equal 697, image.width
    assert_equal 0.697, image.megapixels
    assert_equal 697000, image.pixelarea
    assert_equal "0.7mp", image.megapixels_humanized
    assert_equal "RGB", image.colorspace
    assert_equal 119_333, image.filesize
    assert_equal "abb4755aff726b0c4ac77c7be07b4776", image.checksum
    assert_equal "ed3d64e1569e73aa0b4947cb4bc39618354ee260", image.checksum(format: :sha1, force: true)
    assert_equal ".jpg", image.preferred_extension

    assert_predicate image, :raster?
    refute_predicate image, :vector?
    refute_predicate image, :eps?

    refute_predicate image, :remote?
  end

  def test_scaling_included
    image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
    scaling = image.dimensions_for_target_pixel_area(3_000_000)
    assert_equal 1447, scaling.width
    assert_equal 2075, scaling.height
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

  def test_mime_type_for_masquerading_png
    image = ImageWrangler::Image.new(raster_path("png_as_jpg.jpg"))
    assert_equal "image/png", image.mime_type
  end

  def test_mime_type_for_webp
    image = ImageWrangler::Image.new(raster_path("valid_pam_format.webp"))
    assert_equal "image/webp", image.mime_type
  end

  def test_mime_type_for_jpg_2000
    image = ImageWrangler::Image.new(raster_path("valid_jpeg_2000.jp2"))
    assert_equal "image/jp2", image.mime_type
  end

  # MiniMagick handler specifies `image/psd` so we prefer
  # file system/header `Content-Type` value
  def test_mime_type_for_psd
    image = ImageWrangler::Image.new(raster_path("layers.psd"))
    assert_equal "image/vnd.adobe.photoshop", image.mime_type
  end

  def test_pdf_load
    image = ImageWrangler::Image.new(vector_path("valid.pdf"))
    assert_equal "application/pdf", image.mime_type
    assert_equal ".pdf", image.preferred_extension
    assert_equal "PDF", image.file_format
    assert_predicate image, :vector?
    assert_predicate image, :pdf?
    refute_predicate image, :eps?
  end

  def test_basic_attributes_vector
    image = ImageWrangler::Image.new(vector_path("valid.eps"))

    assert_equal "application/postscript", image.mime_type
    assert_equal 503, image.height
    assert_equal 990, image.width
    assert_equal "CMYK", image.colorspace
    assert_equal 1_425_512, image.filesize
    assert_equal "21de1f0f359eb03f0224f4bcc00384fe", image.checksum
    refute_predicate image, :raster?
    assert_predicate image, :vector?
    assert_predicate image, :eps?
    refute_predicate image, :pdf?
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
    subject = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
    assert subject.mtime.respond_to?(:year)
    assert(subject.mtime < Time.now)
  end

  def test_mtime_with_remote_file
    subject = ImageWrangler::Image.new("#{httpserver}/images/raster/srgb.jpg")
    assert subject.mtime.respond_to?(:year)
    assert(subject.mtime < Time.now)
  end
end
