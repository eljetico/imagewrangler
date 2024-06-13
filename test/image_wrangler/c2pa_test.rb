# frozen_string_literal: true

require_relative "../test_helper"

module ImageWrangler
  class C2paTest < Minitest::Test
    def setup
      @c2pa_camera = raster_path("c2pa/truepic-20230212-camera.jpg")
      @c2pa_invalid = raster_path("c2pa/adobe-20220124-E-dat-CA.jpg")
      @empty_file = raster_path("empty_file.jpeg")
      @no_c2pa = raster_path("valid_jpg.jpg")
      @non_image_file = nonimage_path("plaintext.txt")
      @composite = raster_path("ai_composite_with_trained_algorithmic_media.jpg")
      @subject = ImageWrangler::C2pa
    end

    def test_raises_error_when_command_missing
      assert_raises ImageWrangler::Error do
        @subject.new(@c2pa_camera, {command: "nonexistent_command"})
      end
    end

    def test_extraction_when_no_c2pa
      subject = @subject.new(@composite)
      assert_equal({}, subject.manifests)
    end

    def test_present_with_c2pa
      subject = @subject.new(@c2pa_camera)
      assert subject.present?
    end

    def test_remote_read
      url = "#{httpserver}/images/raster/c2pa/truepic-20230212-camera.jpg"
      subject = @subject.new(url)
      assert subject.present?
    end

    def test_remote_read_missing_file
      url = "#{httpserver}/missing_file.jpg"
      err = assert_raises ImageWrangler::Error do
        @subject.new(url)
      end

      assert_match(/not found/i, err.message)
    end

    def test_empty_file
      assert_raises ImageWrangler::Error do
        @subject.new(@empty_file)
      end
    end

    def test_non_image_file
      subject = @subject.new(@non_image_file)
      refute subject.present?
    end

    def test_valid_c2pa
      subject = @subject.new(@c2pa_camera)
      assert subject.valid?
    end

    def test_invalid_c2pa
      subject = @subject.new(@c2pa_invalid)
      refute subject.valid?
    end

    def test_valid_without_c2pa
      subject = @subject.new(@no_c2pa)
      assert subject.valid?
    end
  end
end
