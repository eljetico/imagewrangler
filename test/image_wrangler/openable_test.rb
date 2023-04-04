# frozen_string_literal: true

require "tempfile"
require_relative "../test_helper"

module ImageWrangler
  class OpenableTest < Minitest::Test
    def setup
      @klass = ImageWrangler::Openable
    end

    def test_handles_on_disk_file_paths
      uri = raster_path("test_out.jpg")
      subject = @klass.for uri

      assert subject.respond_to?(:stream)
      assert_equal(".jpg", subject.extension)

      s = subject.stream
      assert_equal "100644", s.lstat.mode.to_s(8)
      s.close
    end

    def test_handles_remote_file_paths
      uri = "#{httpserver}/images/raster/valid_jpg.jpg"
      subject = @klass.for(uri)

      s = subject.stream
      assert_equal 200, s.data[:status]
      s.close
    end

    def test_handles_exceptions
      uri = "#{httpserver}/images/raster/missing.jpg"
      subject = @klass.for(uri)

      err = assert_raises ImageWrangler::Error do
        subject.stream
      end

      assert_match(/missing/, err.message)
    end
  end
end
