# frozen_string_literal: true

require "mini_exiftool"
require "tempfile"

require_relative "../test_helper"

module ImageWrangler
  class MetdadataTest < Minitest::Test
    def setup
      @temp_file = Tempfile.new("test")
      @org_filename = raster_path("valid_jpg.jpg")
      @temp_filename = @temp_file.path
      FileUtils.cp(@org_filename, @temp_filename)
      @subject = ImageWrangler::Metadata.new(@temp_filename)
    end

    def teardown
      @temp_file.close
    end

    def test_ensure_using_local_exiftool
      assert_match(/vendor\/Image-ExifTool/, MiniExiftool.command)
    end

    def test_simple_accessor
      assert_equal "valid_jpg", @subject.get_tag("title")
      assert_equal "Amanda Hall/Robert Harding", @subject.get_tag("Credit")
    end

    def test_xmp_tag_write
      assert @subject.write_tags({"AssetID" => "Timbo"})
      assert_equal(2000, File.size(@temp_filename))
    end
  end
end
