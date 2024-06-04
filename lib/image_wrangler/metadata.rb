# frozen_string_literal: true

require "mini_exiftool"
require "open3"

module ImageWrangler
  # Interface to Exif, XMP, IPTC metadata
  class Metadata
    CONTROLLED_VALUES = {
      ai_created: "trainedAlgorithmicMedia",
      ai_modified: "compositeWithTrainedAlgorithmicMedia"
    }.freeze

    attr_reader :exiftool

    # Provides high-level access to image IPTC/Exif/XMP metadata.
    # Uses <tt>exiftool</tt> via <tt>MiniExiftool</tt> gem, and provides some
    # additional convenience methods.
    #
    # @param filepath [String] path/URL to image file
    # @param opts [Hash] optional, options to pass to MiniExiftool (note: not supported for remote files)
    def initialize(filepath, opts = OPTS)
      @exiftool = instantiate_exiftool(filepath, opts)
    end

    # Returns true if IPTC:DigitalSourceType is set to "trainedAlgorithmicMedia"
    def ai_created?
      @ai_created ||= get_tag("DigitalSourceType").to_s.match?(/#{CONTROLLED_VALUES[:ai_created]}/)
    end

    # Returns true if IPTC:DigitalSourceType is set to "compositeWithTrainedAlgorithmicMedia"
    def ai_modified?
      @ai_modified ||= get_tag("DigitalSourceType").to_s.match?(/#{CONTROLLED_VALUES[:ai_modified]}/)
    end

    def get_tag(tag)
      @exiftool[tag]
    end
    alias_method :[], :get_tag
    alias_method :tag, :get_tag

    def to_hash
      @exiftool.to_hash
    end
    alias_method :get_all_tags, :to_hash
    alias_method :all_tags, :to_hash

    def write_tags(tags)
      return true if tags.empty?

      tags.each_pair do |tag, value|
        @exiftool.send(:"#{tag}=", value)
      end

      @exiftool.save!

      true
    end

    private

    def instantiate_exiftool(filepath, opts)
      remote_file = filepath.to_s.match(/\Ahttps?:/i).to_a.any?
      remote_file ? from_remote(filepath, opts) : from_local(filepath, opts)
    end

    def from_local(filepath, opts)
      MiniExiftool.new(filepath, opts)
    end

    # Extract metadata from remote location
    # Using curl here to enable piping to Exiftool, and to
    # ensure proxy and no_proxy settings are respected.
    # See: https://exiftool.org/exiftool_pod.html#PIPING-EXAMPLES
    def from_remote(url, opts)
      curl_cmd = ["curl", "-s", url].shelljoin
      exif_cmd = [MiniExiftool.command, "-fast", "-j", "-"].shelljoin

      # Using the interpolated form here is not ideal: not sure how
      # to incorporate the pipe character...
      # Using backticks is not safe, using Open3.pipeline_r opens
      # two subprocesses which can be problematic with `Process.waitall`.
      #
      # Open3.pipeline_r example:
      #
      # json = Open3.pipeline_r(curl_cmd, exif_cmd) { |o, ts|
      #  o.read
      # }
      # Process.waitall # waits for all children to finish
      #
      json, _status = Open3.capture2("#{curl_cmd} | #{exif_cmd}")
      MiniExiftool.from_hash(JSON.parse(json)[0], opts)
    end
  end
end
