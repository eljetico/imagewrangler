# frozen_string_literal: true

require "mini_exiftool"

module ImageWrangler
  # Interface to Exif, XMP, IPTC metadata
  class Metadata
    def initialize(filepath)
      @exiftool = MiniExiftool.new(filepath)
    end

    def get_tag(tag)
      @exiftool[tag]
    end

    def to_hash
      @exiftool.to_hash
    end

    def write_tags(tags)
      return true if tags.empty?

      tags.each_pair do |tag, value|
        @exiftool.send("#{tag}=", value)
      end

      @exiftool.save
    end
  end
end
