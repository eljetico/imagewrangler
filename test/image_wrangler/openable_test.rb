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

      stream = subject.stream
      assert_equal "100644", stream.lstat.mode.to_s(8)
      stream.close
    end

    def test_handles_remote_file_paths
      uri = "#{httpserver}/images/raster/valid_jpg.jpg"
      subject = @klass.for uri

      # Down.open provides access to headers
      stream = subject.stream
      assert_equal 200, stream.data[:status]
      stream.close
    end

    def test_handles_exceptions
      uri = "#{httpserver}/images/raster/missing.jpg"

      err = assert_raises ImageWrangler::Error do
        @klass.for(uri).stream
      end

      assert_match(/missing/, err.message)
    end
  end
end
