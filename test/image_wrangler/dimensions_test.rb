# frozen_string_literal: true

require_relative "../test_helper"

module ImageWrangler
  class DimensionsTest < Minitest::Test
    def setup
    end

    def test_initialize
      dims = ImageWrangler::Dimensions.new(990, 503)
      assert_equal "990x503", dims.to_s
      assert_equal([990, 503], dims.to_a)
      assert_equal(4, dims.to_h.size)
      assert_equal(990, dims.max)
    end
  end
end
