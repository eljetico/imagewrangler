# frozen_string_literal: true

require "down"
require "uri"

module ImageWrangler
  # Wraps the supplied file path or url with methods to ensure
  # proxy/no-proxy is respected, via Httpx.
  #
  # The instance is passed to the Handler instance, and is intended
  # to act-like a URI or Pathname
  #
  # If path_url.respond_to? :open, call open and expect an IO
  # otherwise, if path_url.respond_to? :to_str, check if has protocol
  # and if so, convert to URI.parse(path_url), making sure responds to open
  # or, use Pathname.
  # We will only have a filepath or URL, so can short-circuit this
  # logic.
  # We always respond to :open, but may need to set open options for
  # the handler.
  class Openable
    def initialize(path_or_url, options = OPTS)
      @options = {
        down_backend: :httpx
      }
      @path_or_url = path_or_url
      @remote = @path_or_url =~ %r{\A[A-Za-z][A-Za-z0-9+\-.]*://} ? true : false

      # If we're dealing with a remote file, it needs to go
      # through proxy/no-proxy settings. Https handles this by
      # default, using ENV variables.
      Down.backend @options[:down_backend]
    end

    # Options passed to Handler's instantiator method.
    # On-disk files should be opened in binary mode.
    def open_options
      remote? ? {} : {binmode: true}
    end

    def remote?
      @remote
    end

    def to_s
      @remote ? URI.parse(@path_or_url).path : @path_or_url
    end

    # See Down::open for details
    # Returns an IO-like object which uses the Down::Httpx backend
    # to handle proxy duties
    def open(options = OPTS)
      remote? ? Down.open(@path_or_url, open_options.merge(options)) : Pathname.new(@path_or_url).open(**options)
    end
  end
end
