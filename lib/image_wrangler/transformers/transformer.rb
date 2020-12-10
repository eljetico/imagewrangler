# frozen_string_literal: true
require 'fileutils'

require_relative 'component_list'
require_relative 'variant'

module ImageWrangler
  module Transformers
    class Transformer
      attr_reader :image, :menu, :options

      def initialize(filepath, list, options = {})
        @image = instantiate_source_image(filepath)
        @options = {
          errors: ImageWrangler::Errors.new
        }.merge(options)

        @component_list = instantiate_component_list(list)
        ensure_compliance
      end

      def component_list
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
        unless component_list.valid?
          errors.add(:config, component_list.errors.full_messages)
        end

        unless component_list.variants.any?
          errors.add(:component_list, 'cannot be empty')
        end
      end

      def ensure_outfile_removed(filepath)
        FileUtils.rm_f(filepath) if File.exist?(filepath)
      end

      def process
        return false unless valid?

        component_list.variants.each_with_index do |variant, index|
          begin
            variant.process(source_image)
          rescue StandardError => e
            new_message = "failed at index #{index}: #{e.message}"
            ensure_outfile_removed(variant.filepath)
            errors.add(:variant, new_message)
          end
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
