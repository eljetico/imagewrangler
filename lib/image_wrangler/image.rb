# frozen_string_literal: true

require "down"
require "forwardable"
require "marcel"
require "pathname"
require "timeliness"
require_relative "openable"
require_relative "metadata"

module ImageWrangler
  # Default wrapper for image handling
  class Image
    extend Forwardable
    include ScalingHelper

    DEFAULT_TRANSFORMER = ImageWrangler::Transformers::MiniMagick::Transformer

    attr_reader :filepath

    def_delegators :metadata_delegate, :get_tag, :get_all_tags
    def_delegators :@openable, :remote?, :url?

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
        exiftool_config: nil,
        handler: ImageWrangler::Handlers::MiniMagickHandler.new,
        down_backend: :httpx,
        errors: ImageWrangler::Errors.new,
        logger: ImageWrangler::Logger.new($stdout, level: Logger::FATAL)
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

    def checksum(opts = OPTS)
      options = {
        format: :md5,
        force: false
      }.merge(opts)

      if options[:force]
        return Image.checksum(@handler.loaded_path, format: options[:format])
      end

      @checksum ||= Image.checksum(@handler.loaded_path, format: options[:format])
    end

    def errors
      @options[:errors]
    end

    def file_attributes
      @file_attributes ||= ImageWrangler::FileAttributes.new
    end

    def handler
      @handler ||= @options[:handler]
    end

    def logger
      @logger ||= @options[:logger]
    end

    def metadata_delegate
      @metadata_delegate ||= begin
        config = @options.keep_if { |k| k == :exiftool_config }
        ImageWrangler::Metadata.new(@filepath, config)
      end
    end

    def mime_type
      @mime_type = file_attributes.mime_type || handler.mime_type
    end

    def mtime
      file_attributes.mtime
    end

    # See DEFAULT_TRANSFORMER for options
    def transformer(component_list, klass = nil, options = OPTS)
      # Swap klass with options
      if klass.is_a?(Hash)
        options = klass
        transformer_klass = DEFAULT_TRANSFORMER
      else
        transformer_klass = klass || DEFAULT_TRANSFORMER
      end

      transformer_klass.new(self, component_list, options)
    end

    def transform(component_config, transformer_klass = nil, options = OPTS)
      transformer = transformer(component_config, transformer_klass, options)
      return false unless transformer.valid? # Sets errors on this instance
      transformer.process
    end

    def validate
      errors.clear

      yield self if block_given?

      errors.empty?
    end

    # `tags` should be string-keyed hash
    def write_tags(tags, reload = true)
      metadata_delegate.write_tags(tags)
      reload! if reload # could be slow
    end

    private

    def load_image
      @openable = ImageWrangler::Openable.new(@filepath, @options)
      file_attributes.from_stream(@openable.stream)
      handler.load_from_stream(@openable.stream, @openable.extension)
    ensure
      @openable&.close_stream
    end
    alias_method :reload!, :load_image
  end
end
