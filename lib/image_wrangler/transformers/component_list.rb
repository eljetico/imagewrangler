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
          error_handler: ImageWrangler::Errors.new
        }.merge(options)

        @variants = []
        @list = list
      end

      def [](index)
        @variants[index]
      end

      def errors
        @errors ||= @options[:error_handler]
      end

      # rubocop:disable Metrics/MethodLength
      def instantiate_variants
        @variants.clear

        Array(list).compact.each_with_index do |config, index|
          variant = variant_handler.new(config)
          variant.validate!
          if variant.valid?
            @variants.push(variant)
          else
            errors.add(:variant, "#{index}: #{variant.errors.full_messages.join("; ")}")
          end
        end

        @variants.any?
      end
      # rubocop:enable Metrics/MethodLength

      def valid?
        errors.empty?
      end

      def variant_handler
        ImageWrangler::Transformers::Variant
      end
    end
  end
end
