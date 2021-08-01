# frozen_string_literal: true

require "mini_exiftool"
require "tempfile"

require_relative "../test_helper"

module ImageWrangler
  class MetdadataTest < Minitest::Test
    def setup
      @temp_file = Tempfile.new("test")
      @org_filename = raster_path("valid_jpg_600px.jpg")
      @temp_filename = @temp_file.path
      FileUtils.cp(@org_filename, @temp_filename)
      @subject = ImageWrangler::Metadata.new(@temp_filename)
    end

    def teardown
      @temp_file.close
      @temp_file.delete
    end

    def test_ensure_using_local_exiftool
      assert_match(/vendor\/Image-ExifTool/, MiniExiftool.command)
    end

    def test_simple_accessor
      assert_equal "808-185", @subject.get_tag("title")
      assert_equal "Amanda Hall/Robert Harding", @subject.get_tag("Credit")
    end

    def test_xmp_tag_write
      assert @subject.write_tags({"AssetID" => "12345"})
    end
  end
end