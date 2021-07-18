# frozen_string_literal: true

require "fileutils"

require_relative "component_list"
require_relative "variant"

module ImageWrangler
  # Transformer process images
  module Transformers
    # Abstract Transformer class
    class Transformer
      attr_reader :component_list, :image, :menu, :options

      OPTS = {}.freeze

      def initialize(filepath, list, options = OPTS)
        @image = instantiate_source_image(filepath)
        @options = {
          cascade: false,
          errors: ImageWrangler::Errors.new
        }.merge(options)

        @component_list = instantiate_component_list(list)
        ensure_compliance
      end

      # Returns an ImageWrangler::Image instance
      # If cascading is disabled, we use the source file
      # for all components, otherwise, attempt to retrieve
      # the previously rendered filepath.
      # WARNING, there is no pixel dimension checking here
      # so upscaling from a smaller file is possible if
      # the component list is incorrectly ordered.
      def assert_source_image(variant_index)
        return source_image if variant_index.zero?

        if @options[:cascade]
          variant = component_list[variant_index - 1]
          return instantiate_source_image(variant.filepath) if variant && File.exist?(variant.filepath)
        end

        source_image
      end

      def components
        @component_list
      end

      def errors
        @errors ||= @options[:errors]
      end

      def instantiate_source_image(item)
        item.is_a?(ImageWrangler::Image) ? item : ImageWrangler::Image.new(item)
      end

      def instantiate_component_list(list)
        raise NotImplementedError
      end

      def ensure_compliance
        errors.add(:config, component_list.errors.full_messages) unless component_list.valid?

        errors.add(:component_list, "cannot be empty") unless component_list.variants.any?
      end

      def ensure_outfile_removed(filepath)
        FileUtils.rm_f(filepath) if File.exist?(filepath)
      end

      def process &block
        return false unless valid?

        component_list.each_with_index do |variant, index|
          # rubocop:disable Style/RedundantBegin
          begin
            variant.source_image = assert_source_image(index)
            variant.process
            yield(variant) if block
          rescue => e
            new_message = "failed at index #{index}: #{e.message}"
            ensure_outfile_removed(variant.filepath)
            errors.add(:variant, new_message)
          end
          # rubocop:enable Style/RedundantBegin
        end

        valid?
      end

      def source_image
        @image
      end

      def valid?
        errors.empty?
      end
    end
  end
end
