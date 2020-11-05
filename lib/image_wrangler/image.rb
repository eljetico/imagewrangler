# frozen_string_literal: true

module ImageWrangler
  class Image
    attr_reader :filepath

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

    def validate
      errors.clear

      yield self if block_given?

      errors.empty?
    end

    private

    def load_image
      handler.load_image(@filepath)
    end
  end
end
