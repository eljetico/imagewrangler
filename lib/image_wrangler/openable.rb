# frozen_string_literal: true

require "down"
require "uri"

module ImageWrangler
  # Factory class to return an IO-like object for use with
  # MiniMagick and MiniExiftool
  #
  class Openable
    def self.for(uri_or_openable, options = OPTS)
      uri_or_openable.is_a?(ImageWrangler::Openable) ? uri_or_openable : ImageWrangler::Openable.new(uri_or_openable, options)
    end

    # Returns an array containing `[IO-like object, extension]`
    def initialize(path_or_url, opts = OPTS)
      @path_or_url = path_or_url
      @options = {down_backend: :httpx}.merge(opts)
      Down.backend @options[:down_backend]
    
      @remote = @path_or_url =~ %r{\A[A-Za-z][A-Za-z0-9+\-.]*://} ? true : false
    end

    def extension
      @extension ||= begin
        uri = @remote ? URI.parse(@path_or_url) : @path_or_url
        uri_s = uri.is_a?(URI::Generic) ? uri.path : uri.to_s
        File.extname(uri_s)
      end
    end

    def remote?
      @remote
    end

    # Returns an IO-like object for use with MiniMagick `read`.
    # Ensure this is closed after use.
    def stream
      @_stream ||= @remote ? Down.open(@path_or_url) : Pathname.new(@path_or_url).open({binmode: true})
    rescue Down::NotFound, Errno::ENOENT => _e
      raise ImageWrangler::Error, "not found at '#{@path_or_url}'"
    rescue => e
      raise ImageWrangler::Error, "unhandled Openable exception #{e.message} - #{e.backtrace.join("\n")}"
    end
  end
end
