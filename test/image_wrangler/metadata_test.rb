# frozen_string_literal: true

require "tempfile"
require_relative "../test_helper"

module ImageWrangler
  class MetadataTest < Minitest::Test
    def setup
      @temp_file = Tempfile.new("test")
      @org_filename = raster_path("valid_jpg_600px.jpg")
      @config_file = config_path("ExifTool_config")
      @temp_filename = @temp_file.path
      FileUtils.cp(@org_filename, @temp_filename)
      @subject = ImageWrangler::Metadata.new(@temp_filename)
    end

    def teardown
      @temp_file.close
      @temp_file.delete
    end

    def test_direct_access_to_tags
      assert_equal "808-185", @subject["title"]
    end

    def test_ensure_using_local_exiftool
      assert_match(/vendor\/Image-ExifTool/, MiniExiftool.command)
    end

    def test_simple_accessor
      assert_equal "808-185", @subject.tag("title")
      assert_equal "Amanda Hall/Robert Harding", @subject.tag("Credit")
    end

    def test_xmp_tag_write
      @subject.write_tags({"AssetID" => "12345"})
      @subject.exiftool.reload

      assert_equal "12345", @subject.tag("AssetID").to_s
    end

    def test_custom_xmp_tags_discoverable
      custom_xmp = raster_path("custom_xmp.jpg")
      subject = ImageWrangler::Metadata.new(custom_xmp)
      assert subject.to_hash.key?("CustomField24")
    end

    def test_can_supply_exiftool_config_file
      custom_xmp = raster_path("custom_xmp.jpg")
      subject = ImageWrangler::Metadata.new(custom_xmp, {exiftool_config: @config_file})
      assert_equal @config_file, subject.exiftool.config_file
    end

    # CustomField24 only works because overridden MiniExiftool passes the tag through
    # and it is recognized by the config file.
    def test_can_write_to_namespaced_tag_with_config
      subject = ImageWrangler::Metadata.new(@temp_filename, {exiftool_config: @config_file})
      content = "New value"
      subject.write_tags("CustomField24" => content)
      assert_equal content, subject.tag("CustomField24")
    end

    # CustomField24 works because overridden MiniExiftool parses the embedded tag
    # into its internal TagHash.
    # CustomField59 does not work because even though parsed to TagHash, the config
    # file does not recognize it
    def test_can_write_to_custom_tag_with_config
      custom_xmp = raster_path("custom_xmp.jpg")
      FileUtils.cp(custom_xmp, @temp_filename)

      subject = ImageWrangler::Metadata.new(@temp_filename, {exiftool_config: @config_file})
      content = "New value"
      subject.write_tags("CustomField24" => content)
      assert_equal content, subject.tag("CustomField24")

      assert_raises MiniExiftool::Error do
        subject.write_tags("CustomField59" => "Should fail")
      end
    end

    def test_cannot_write_to_custom_tag_without_config
      assert_raises MiniExiftool::Error do
        @subject.write_tags("CustomField49" => "Timbo")
      end
    end

    # Remote read
    def test_remote_read
      url = "#{httpserver}/images/raster/valid_jpg.jpg"
      subject = ImageWrangler::Metadata.new(url)
      assert_equal "Times Square", subject["Sub-location"]
    end
  end
end
