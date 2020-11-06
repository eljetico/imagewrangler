# frozen_string_literal: true

module ImageWrangler
  module Transformers
    class Transformer
      attr_reader :image, :menu

      def initialize(filepath, menu, options = {})
        @image = instantiate_image(filepath)
        @menu = instantiate_menu(menu)

        @options = {
          errors: ImageWrangler::Errors.new
        }.merge(options)

        ensure_compliance
      end

      def errors
        @errors ||= @options[:errors]
      end

      def instantiate_image(item)
        item.is_a?(ImageWrangler::Image) ? item : ImageWrangler::Image.new(item)
      end

      def instantiate_menu(menu)
        raise NotImplementedError
      end

      def ensure_compliance
        unless menu.valid?
          errors.add("Invalid config: #{menu.errors.full_messages}")
        end
      end
    end
  end
end
