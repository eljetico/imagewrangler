# frozen_string_literal: true

require "down"
require "marcel"
require "pathname"
require "timeliness"
require_relative "metadata"

module ImageWrangler
  # Default wrapper for image handling
  class Image
    include ScalingHelper

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
        exiftool_config: nil,
        handler: ImageWrangler::Handlers::MiniMagickHandler.new,
        down_backend: nil,
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

    def get_tag(tag)
      metadata_delegate.get_tag(tag)
    end

    def get_all_tags
      metadata_delegate.to_hash
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

    # Handler may return spurious values
    # rubocop:disable Style/RedundantBegin
    def mime_type
      @mime_type ||= begin
        if remote?
          remote_mime_type || handler.mime_type
        else
          extract_mime_type || handler.mime_type
        end
      end
    end
    # rubocop:enable Style/RedundantBegin

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

    def extract_mime_type
      File.open(@filepath) { |file| Marcel::MimeType.for file }
    end

    def gather_remote_data
      Down.backend @options.fetch(:down_backend, Down::NetHttp)
      remote_file = Down.open(@filepath)
      data = remote_file.data
      remote_file.close
      data
    rescue Down::Error => e
      @logger.debug("Down error: #{e.backtrace.join("\n")}")
      OPTS
    end

    # Use after manipulations which may alter filesize, checksum etc
    def reload!
      load_image
    end

    def remote_data
      @remote_data ||= gather_remote_data
    end

    def remote_headers
      @remote_headers ||= remote_data.fetch(:headers, OPTS)
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

    def remote_mime_type
      return nil unless remote?

      remote_headers.fetch("Content-Type", nil)
    end

    def load_image
      handler.load_image(@filepath)
    end
  end
end
