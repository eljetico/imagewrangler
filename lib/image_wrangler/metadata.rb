# frozen_string_literal: true

require "mini_exiftool"

module ImageWrangler
  # Interface to Exif, XMP, IPTC metadata
  class Metadata
    attr_reader :exiftool

    def initialize(filepath, opts = OPTS)
      @exiftool = instantiate_exiftool(filepath, opts)
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

    def from_remote(url, opts)
      json = `curl -s #{url} | #{MiniExiftool.command} -fast -j -`
      MiniExiftool.from_hash(JSON.parse(json)[0], opts)
    end
  end
end
