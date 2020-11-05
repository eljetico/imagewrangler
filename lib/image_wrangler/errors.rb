# frozen_string_literal: true

module ImageWrangler
  class Error < StandardError; end

  class MissingImageError < Error; end

  class CorruptImageError < Error; end

  class RemoteImageError < Error; end
end
