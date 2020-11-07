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

      def menu
        @menu
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
          errors.add(:config, menu.errors.full_messages)
        end
      end

      def process
        return false unless valid?

        menu.recipes.each_with_index do |recipe, index|
          process_recipe(recipe, index)
        end

        valid?
      end

      def valid?
        errors.empty?
      end
    end
  end
end
