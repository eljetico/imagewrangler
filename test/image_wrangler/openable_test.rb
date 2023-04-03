# frozen_string_literal: true

require "tempfile"
require_relative "../test_helper"

module ImageWrangler
  class OpenableTest < Minitest::Test
    def setup
      @klass = ImageWrangler::Openable
    end

    def test_handles_on_disk_file_paths
      subject = @klass.new raster_path("test_out.jpg")
      assert subject.respond_to?(:open)
      assert subject.respond_to?(:to_s)

      f = subject.open
      assert_equal "100644", f.lstat.mode.to_s(8)
      f.close
    end

    def test_handles_remote_file_paths
      url = "#{httpserver}/images/raster/valid_jpg.jpg"
      subject = @klass.new url
      assert subject.respond_to?(:open)
      assert subject.respond_to?(:to_s)

      # Down.open provides access to headers
      f = subject.open
      assert_equal 200, f.data[:status]
      f.close
    end
  end
end
