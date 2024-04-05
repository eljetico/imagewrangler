# frozen_string_literal: true

require "marcel"
require "timeliness"

module ImageWrangler
  class FileAttributes
    TIME_FORMAT = "ddd, dd mmm yyyy hh:nn:ss GMT"

    def from_stream(stream)
      @attributes = stream.respond_to?(:data) ? from_data(stream) : from_file_io(stream)
      stream.rewind
    end

    def mtime
      @attributes["Last-Modified"]
    end

    def mime_type
      @attributes["Content-Type"]
    end

    # Returns a hash of attributes derived from Down::ChunkedIO data hash
    def from_data(stream)
      stream.data[:headers].dup.tap { |h|
        h["Last-Modified"] = date_time_from_string(date_from_headers(h))
      }
    end

    def from_file_io(stream)
      {
        "Content-Type" => Marcel::MimeType.for(stream),
        "Last-Modified" => stream.mtime
      }
    end

    private

    def date_from_headers(h)
      h["Last-Modified"] || h["Date"]
    end

    def date_time_from_string(str)
      return nil if blank?(str)

      Timeliness.parse(str, format: TIME_FORMAT, zone: :utc)
    rescue => _e
      nil
    end

    def blank?(str)
      str.to_s.strip.eql? ""
    end
  end
end
