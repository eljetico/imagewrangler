# frozen_string_literal: true

require "down"
require "timeliness"

module ImageWrangler
  # Default wrapper for image handling
  class Image
    attr_reader :filepath

    DEFAULT_TRANSFORMER = ImageWrangler::Transformers::MiniMagick::Transformer

    class << self
      def checksum(path, format: :md5)
        {
          sha1: Digest::SHA1.file(path).hexdigest,
          sha256: Digest::SHA256.file(path).hexdigest,
          sha512: Digest::SHA512.file(path).hexdigest,
          md5: Digest::MD5.file(path).hexdigest
        }.fetch(format) { Digest::MD5.file(path).base64digest }
      end

      def remote_location?(path)
        path.to_s.match(/\Ahttps?:/i).to_a.any?
      end
    end

    def initialize(filepath, **options)
      @filepath = filepath
      @options = {
        handler: ImageWrangler::Handlers::MiniMagickHandler.new,
        errors: ImageWrangler::Errors.new
      }.merge(options)

      load_image
    end

    def method_missing(method, *args, &block)
      if handler.respond_to?(method)
        handler.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      handler.respond_to?(method) || super
    end

    def errors
      @options[:errors]
    end

    def handler
      @handler ||= @options[:handler]
    end

    def mtime
      @mtime ||= remote? ? remote_mtime : File.mtime(@filepath)
    rescue => _e
      nil
    end

    def remote?
      @remote ||= ImageWrangler::Image.remote_location?(@filepath)
    end
    alias_method :url?, :remote?

    # See DEFAULT_TRANSFORMER for options
    def transformer(component_list, klass = nil, options = {})
      # Swap klass with options
      if klass.is_a?(Hash)
        options = klass
        transformer_klass = DEFAULT_TRANSFORMER
      else
        transformer_klass = klass || DEFAULT_TRANSFORMER
      end

      transformer_klass.new(self, component_list, options)
    end

    def validate
      errors.clear

      yield self if block_given?

      errors.empty?
    end

    private

    def gather_remote_data
      remote_file = Down.open(@filepath)
      data = remote_file.data
      remote_file.close
      data
    rescue Down::Error => _e
      {}
    end

    def remote_data
      @remote_data ||= gather_remote_data
    end

    def remote_headers
      @remote_headers ||= remote_data.fetch(:headers, {})
    end

    def remote_mtime
      date = remote_headers.fetch("Last-Modified", nil)
      return nil if date.nil?

      # This is a little constrictive
      t_format = "ddd, dd mmm yyyy hh:nn:ss GMT"
      Timeliness.parse(date, format: t_format, zone: :utc)
    rescue => _e
      nil
    end

    def load_image
      handler.load_image(@filepath)
    end
  end
end
