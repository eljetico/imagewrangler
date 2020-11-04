# frozen_string_literal: true

# Version handling for Pickle
module ImageWrangler
  def self.version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 1
    MINOR = 0
    TINY  = 0

    STRING = [MAJOR, MINOR, TINY].compact.join('.')
  end
end

