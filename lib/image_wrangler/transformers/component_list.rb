# frozen_string_literal: true

require "forwardable"

module ImageWrangler
  module Transformers
    # Parse, validate and persist the given list of components
    # `config` is an array of variant configurations suitable for
    # ImageWrangler::Transformers::Variant-like instances
    class ComponentList
      extend Forwardable
      delegate %i[each each_with_index to_a] => :@variants

      attr_reader :variants, :list

      def initialize(list = [], options = OPTS)
        @options = {
          errors: ImageWrangler::Errors.new # ImageWrangler::Image.errors by default
        }.merge(options)

        @variants = []
        @list = list
      end

      def [](index)
        @variants[index]
      end

      def errors
        @errors ||= @options[:errors]
      end

      def instantiate_variants
        @variants.clear

        Array(list).compact.each_with_index do |config, index|
          variant = variant_handler.new(config)
          variant.validate!
          if variant.valid?
            @variants.push(variant)
          else
            errors.add(:variant, "#{index}: #{variant.errors}")
          end
        end

        @variants.any?
      end

      def valid?
        errors.empty?
      end

      def variant_handler
        ImageWrangler::Transformers::Variant
      end
    end
  end
end
