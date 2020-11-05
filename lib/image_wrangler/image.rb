# frozen_string_literal: true

module ImageWrangler
  class Image
    attr_reader :filepath

    def initialize(filepath, **options)
      @filepath = filepath
      @options = {
        handler: ImageWrangler::Handlers::MiniMagickHandler.new
      }.merge(options)

      load_image
    end

    def valid?
      @handler.valid?
    end

    private

    def load_image
      @handler = @options[:handler]
      @handler.load_image(@filepath)
    end
  end
end
