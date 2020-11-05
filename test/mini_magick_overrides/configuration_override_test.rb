# frozen_string_literal: true

require_relative '../test_helper'
require 'image_wrangler'

# rubocop:disable Metrics/ClassLength
class CoonfigurationOverrideTest < Minitest::Test
  def setup
  end

  def test_can_assert_quiet_warnings
    refute MiniMagick.quiet_warnings

    MiniMagick.configure do |config|
      config.quiet_warnings = true
    end

    assert MiniMagick.quiet_warnings
  end
end
