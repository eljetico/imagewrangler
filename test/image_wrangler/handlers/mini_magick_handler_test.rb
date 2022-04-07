# frozen_string_literal: true

require_relative "../../test_helper"

# rubocop:disable Metrics/ClassLength
class MiniMagickHandlerTest < Minitest::Test
  def setup
    @handler = ImageWrangler::Handlers::MiniMagickHandler
    @subject = @handler.new
  end

  def test_initialization_with_local_file
    filepath = raster_path("valid_jpg.jpg")
    assert @subject.load_image(filepath)
  end

  def test_initialization_with_empty_file
    filepath = raster_path("empty_file.jpeg")

    err = assert_raises ImageWrangler::Error do
      @subject.load_image(filepath)
    end

    assert_match(/empty file/, err.message)
    assert_match(/Empty input file/, err.cause.message) # nested error
  end

  def test_initialization_with_missing_file
    filepath = raster_path("missing.jpg")

    err = assert_raises ImageWrangler::Error do
      @subject.load_image(filepath)
    end

    assert_match(/not found at '#{filepath}'/, err.message)
    assert_match(/No such file or directory/, err.cause.message) # nested error
  end

  def test_initialize_with_corrupt_local_file
    err = assert_raises ImageWrangler::Error do
      @subject.load_image(raster_path("corrupt_premature_end.jpg"))
    end

    assert_match(/corrupted file/i, err.message)
    assert_match(/premature end of jpeg file/i, err.cause.message)
  end

  def test_initialize_with_corrupt_remote_file
    stub_request(:get, "https://example.com/corrupt.jpg")
      .to_return(body: File.read(raster_path("corrupt_premature_end.jpg")))

    err = assert_raises ImageWrangler::Error do
      @subject.load_image("https://example.com/corrupt.jpg")
    end

    assert_match(/corrupted file/i, err.message)
  end

  def test_basic_initialization_with_missing_url
    stub_request(:get, "https://example.com/image.jpg")
      .to_return(status: 404, body: "Not found")

    err = assert_raises ImageWrangler::Error do
      @subject.load_image("https://example.com/image.jpg")
    end

    assert_match(/404/i, err.message)
  end

  def test_channel_count
    {
      "valid_jpg.jpg" => 3,
      "grayscale.jpg" => 1,
      "cmyk.jpg" => 4
    }.each_pair do |filename, cc|
      subject = @handler.new
      subject.load_image(raster_path(filename))
      assert_equal cc, subject.channel_count, "#{filename} s/be #{cc} channels"
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def test_attributes_retrieval_local_file
    @subject.load_image(raster_path("valid_jpg.jpg"))

    assert_equal "image/jpeg", @subject.mime_type
    assert_equal 8, @subject.bit_depth
    assert_equal "RGB", @subject.colorspace
    assert_equal "abb4755aff726b0c4ac77c7be07b4776", @subject.checksum
    assert_equal 1_000, @subject.height
    assert_equal 697, @subject.width
    assert_equal 119_333, @subject.filesize
    assert_equal "JPEG", @subject.format
    assert_equal "TopLeft", @subject.orientation
    assert_equal "Adobe RGB (1998)", @subject.icc_name
    refute @subject.visually_corrupt?
  end
  # rubocop:enable Metrics/MethodLength

  def test_attributes_retrieval_remote_file
    stub_request(:get, "https://example.com/image.jpg")
      .to_return(body: File.read(raster_path("cmyk.jpg")))

    @subject.load_image("https://example.com/image.jpg")

    assert_equal "image/jpeg", @subject.mime_type
    assert_equal "CMYK", @subject.colorspace
    assert_equal ".jpg", @subject.extension
    assert @subject.valid_extension?
    assert_equal "638595b250d6afdf8f62dcd299da1ad0", @subject.checksum
    assert_equal "U.S. Web Coated (SWOP) v2", @subject.icc_name
    refute @subject.visually_corrupt?
  end
  # rubocop:enable Metrics/AbcSize

  def test_clipping_paths
    @subject.load_image(raster_path("clipping_path.jpg"))
    assert_predicate @subject, :paths?

    assert_equal "Canon EOS 5D", @subject.camera_model

    subject = @handler.new
    subject.load_image(raster_path("valid_jpg.jpg"))
    refute_predicate subject, :paths?
  end

  def test_iptc_create_date
    @subject.load_image(raster_path("grayscale.jpg"))
    refute @subject.iptc_date_created.nil?
    assert_equal 1970, @subject.iptc_date_created.year
  end

  def test_camera_make_and_model
    @subject.load_image(raster_path("clipping_path.jpg"))
    assert_equal "Canon", @subject.camera_make
    assert_equal "Canon EOS 5D", @subject.camera_model

    subject = @handler.new
    subject.load_image(raster_path("valid_jpg.jpg"))
    assert_nil subject.camera_make
  end

  def test_color_managed_raster_with_profile
    subject = @handler.new
    subject.load_image(raster_path("valid_jpg.jpg"))
    assert subject.color_managed?
    assert_equal "Adobe RGB (1998)", subject.icc_name

    subject = @handler.new
    subject.load_image(raster_path("cmyk.jpg"))
    assert subject.color_managed?
    assert_equal "U.S. Web Coated (SWOP) v2", subject.icc_name
  end

  def test_color_managed_raster_without_profile
    subject = @handler.new
    subject.load_image(raster_path("cmyk_no_profile.jpg"))
    refute subject.color_managed?
    assert_nil subject.icc_name
  end

  # ICC profiles cannot be embedded in EPS files (postscript limitation)
  def test_color_managed_vector_without_profile
    subject = @handler.new
    subject.load_image(vector_path("valid.eps"))
    refute subject.color_managed?
    assert_nil subject.icc_name
  end

  def test_raster_detection
    @subject.load_image(raster_path("grayscale.jpg"))
    assert @subject.raster?
    refute @subject.vector?
  end

  def test_vector_detection
    @subject.load_image(vector_path("valid.eps"))
    assert_equal "application/postscript", @subject.mime_type
    assert @subject.vector?
    assert @subject.postscript?
    refute @subject.raster?
    assert_equal 3.0, @subject.postscript_version
  end

  # Two different file structure formats
  def test_vector_metadata_regular_format
    @subject.load_image(vector_path("valid.eps"))
    assert_equal 503, @subject.height
    assert_equal 990, @subject.width
  end

  def test_vector_metadata_second_format
    @subject.load_image(vector_path("valid_2.eps"))
    assert_equal 348, @subject.height
    assert_equal 649, @subject.width
  end

  def test_pages_detection
    @subject.load_image(vector_path("multi_page_scanned.pdf"))
    assert_equal "application/pdf", @subject.mime_type
    assert_equal 2, @subject.pages.length
    assert_predicate @subject, :image_sequence?
  end

  # PSD mime type can be any of:
  # application/x-photoshop
  # application/photoshop
  # application/psd
  # image/vnd.adobe.photoshop
  # image/psd
  #
  # This result is a fall-through (IM doesn't report via info methods)
  def test_layers_detection
    @subject.load_image(raster_path("valid_jpg.jpg"))
    assert_equal 1, @subject.layers.length

    subject = @handler.new
    subject.load_image(raster_path("layers.psd"))
    assert_equal "image/psd", subject.mime_type
    assert_equal 2, subject.layers.length
  end

  def test_valid_jpeg_two_k
    @subject.load_image(raster_path("valid_jpeg_2000.jp2"))
    assert_equal "image/jp2", @subject.mime_type
    assert_equal "JP2", @subject.type
    assert @subject.raster?
  end

  # JPEG2000 files without extensions cannot be identified by magic number with
  # this version of IM, being an issue with IMs magic pattern config
  # See https://github.com/ImageMagick/ImageMagick/issues/28
  # and associated commit
  def test_jpeg_2000_without_extension
    err = assert_raises ImageWrangler::Error do
      @subject.load_image(raster_path("valid_jpeg_2000"))
    end

    assert_equal "MiniMagick error", err.message
    assert_match(/no decode delegate/, err.cause.message)
  end

  # Similar to the above, masquerading JPEG2000s do not play nice
  # IM uses the filename/ext 'hint' instead of magic number
  def test_jpeg_2000_as_jpg
    err = assert_raises ImageWrangler::Error do
      @subject.load_image(raster_path("jpeg_2000_as_jpg.jpg"))
    end

    assert_equal "MiniMagick error", err.message
    assert_match(/Not a JPEG file/, err.cause.message)
  end
end
# rubocop:enable Metrics/ClassLength
