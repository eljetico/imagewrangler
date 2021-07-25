# frozen_string_literal: true

require "mini_exiftool"
require_relative "../test_helper"

module ImageWrangler
  class MetdadataTest < Minitest::Test
    def setup
      @copy_file = "/tmp/test_write_image.jpg"
    end

    def teardown
      # File.unlink(@copy_file) if File.exist?(@copy_file)
    end

    def test_ensure_using_local_exiftool
      assert_match(/vendor\/Image-ExifTool/, MiniExiftool.command)
    end

    def test_simple_accessor
      subject = ImageWrangler::Metadata.new(raster_path("valid_jpg.jpg"))
      assert_equal "valid_jpg", subject.get_tag("title")
      assert_equal "Amanda Hall/Robert Harding", subject.get_tag("Credit")
    end

    def test_xmp_tag_write
      FileUtils.cp(raster_path("valid_jpg.jpg"), @copy_file)
      # subject = ImageWrangler::Metadata.new(@copy_file)
      # assert subject.write_tags({"AssetID" => "Timbo"})
      #
      # photo = MiniExiftool.new(@copy_file)
      # assert_equal("Timbo", photo.AssetID)
      # assert(File.size(@copy_file) > 382000)
    end
  end
end
