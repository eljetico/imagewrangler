# frozen_string_literal: true

# Version handling for Pickle
module ImageWrangler
  def self.version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 0
    MINOR = 1
    TINY  = 1
    PRE = 'alpha'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end
end
