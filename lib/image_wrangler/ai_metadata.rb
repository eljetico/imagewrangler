# frozen_string_literal: true

require_relative "c2pa"
require_relative "metadata"

module ImageWrangler
  class AiMetadata
    CONTROLLED_VALUES = {
      ai_created: "trainedAlgorithmicMedia",
      ai_modified: "compositeWithTrainedAlgorithmicMedia"
    }.freeze

    # Provides AI metadata disclosure from C2PA or XMP, if available
    #
    # @param path_or_url [String] path/URL to image file
    # @param opts [Hash] optional, options to pass to C2pa and Metadata classes
    # @example
    #   subject = ImageWrangler::AiMetadata.new("path/to/image.jpg", {logger: ImageWrangler::Logger.new($stdout)})
    def initialize(path_or_url, opts = ImageWrangler::OPTS)
      @options = {
        logger: ImageWrangler::Logger.new(nil)
      }.merge(opts)

      @from_xmp = false
      @from_c2pa = false

      @path_or_url = path_or_url
    end

    def created_with_ai?
      @_created_with_ai ||= digital_source_type.to_s.match(/#{CONTROLLED_VALUES[:ai_created]}/)
    end

    def digital_source_type
      @_digital_source_type ||= extract_digital_source_type
    end

    def from_xmp?
      @from_xmp
    end

    def from_c2pa?
      @from_c2pa
    end

    def modified_with_ai?
      @_modified_with_ai ||= digital_source_type.to_s.match(/#{CONTROLLED_VALUES[:ai_modified]}/)
    end

    private

    def extract_digital_source_type
      if valid_source_type?(metadata_digital_source_type)
        log_extraction(metadata_digital_source_type, "xmp")
        return metadata_digital_source_type
      elsif valid_source_type?(c2pa_digital_source_type)
        log_extraction(c2pa_digital_source_type, "c2pa")
        return c2pa_digital_source_type
      end

      nil
    end

    def log_extraction(digital_source_type, source)
      logger.info("#{digital_source_type} from #{source.upcase}")
      instance_variable_set(:"@from_#{source}", true)
    end

    def logger
      @options[:logger]
    end

    def valid_source_type?(source_type = nil)
      return false if source_type.to_s.empty?

      CONTROLLED_VALUES.each_pair do |_, regex|
        if source_type =~ /#{regex}/
          return true
        end
      end

      false
    end

    def c2pa_digital_source_type
      @_c2pa_digital_source_type ||= begin
        c2pa = C2pa.new(@path_or_url, @options)
        c2pa.digital_source_types.find do
          valid_source_type?(_1)
        end
      end
    end

    def metadata_digital_source_type
      @_metadata_digital_source_type ||= Metadata.new(@path_or_url, @options).digital_source_type
    end
  end
end
