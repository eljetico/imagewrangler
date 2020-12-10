# frozen_string_literal: true
require 'forwardable'

module ImageWrangler
  module Transformers
    # Parse, validate and persist the given list of components
    # `config` is an array of variant configurations suitable for
    # ImageWrangler::Transformers::Variant-like instances
    class ComponentList
      extend Forwardable
      delegate [:each, :each_with_index, :to_a] => :@variants

      def initialize(list = [], options = {})
        @options = {
          error_handler: ImageWrangler::Errors.new
        }.merge(options)

        @variants = []
        @list = list
      end

      def [](index)
        @variants[index]
      end

      def errors
        @error_handler ||= @options[:error_handler]
      end

      def instantiate_variants
        @variants.clear

        Array(list).compact.each_with_index do |config, index|
          variant = variant_handler.new(config)
          variant.validate!
          unless variant.valid?
            errors.add(:variant, "#{index}: #{variant.errors.full_messages.join('; ')}")
          else
            @variants.push(variant)
          end
        end

        @variants.any?
      end

      def list
        @list
      end

      def variants
        @variants # may need to order by pixel dims if cascading?
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
