# frozen_string_literal: true

require_relative "../test_helper"

module ImageWrangler
  class AiMetadataTest < Minitest::Test
    def setup
      @klass = ImageWrangler::AiMetadata

      @options = {
        logger: Logger.new(nil)
      }
    end

    def test_extracts_digital_source_type_from_xmp
      composite = raster_path("ai_composite_with_trained_algorithmic_media.jpg")
      subject = @klass.new(composite, @options)
      assert_match(/compositeWithTrainedAlgorithmicMedia\z/, subject.digital_source_type)
      refute subject.from_c2pa?
      assert subject.from_xmp?

      from_trained = raster_path("ai_trained_algorithmic_media.jpg")
      subject = @klass.new(from_trained, @options)
      assert_match(/trainedAlgorithmicMedia\z/, subject.digital_source_type)
      refute subject.from_c2pa?
      assert subject.from_xmp?
    end

    def test_extracts_digital_source_type_from_c2pa
      composite = raster_path("c2pa/gregs-hotdogs.jpg")
      subject = @klass.new(composite, @options)
      assert_match(/compositeWithTrainedAlgorithmicMedia\z/, subject.digital_source_type)
      refute subject.from_xmp?
      assert subject.from_c2pa?

      created = raster_path("c2pa/4-firefly.jpg")
      subject = @klass.new(created, @options)
      assert_match(/trainedAlgorithmicMedia\z/, subject.digital_source_type)
      refute subject.from_xmp?
      assert subject.from_c2pa?
    end

    def test_extraction_from_non_ai_file_is_nil_with_empty_log
      composite = raster_path("valid_jpg.jpg")
      subject = @klass.new(composite, {logger: ImageWrangler::Logger.new($stdout)})

      out, _err = capture_subprocess_io do
        assert_nil subject.digital_source_type
        refute subject.from_xmp?
        refute subject.from_c2pa?
      end

      assert_empty(out)
    end

    def test_logging
      composite = raster_path("c2pa/gregs-hotdogs.jpg")
      subject = @klass.new(composite, {logger: ImageWrangler::Logger.new($stdout)})

      out, _err = capture_subprocess_io do
        assert_match(/compositeWithTrainedAlgorithmicMedia\z/, subject.digital_source_type)
      end

      assert_match(/compositeWithTrainedAlgorithmicMedia from C2PA/, out)
    end
  end
end
