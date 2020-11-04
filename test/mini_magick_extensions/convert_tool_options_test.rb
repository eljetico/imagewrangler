# frozen_string_literal: true

require_relative '../test_helper'
require 'image_wrangler'

# rubocop:disable Metrics/ClassLength
class ConvertToolOptionsTest < Minitest::Test
  def setup
  end

  def test_image_settings_options
    all_options = MiniMagick::Tool::Convert.image_settings_options
    assert(all_options.length > 10) # arbitrary test value
    assert((['depth', 'colorspace', 'format'] - all_options).empty?)
  end

  def test_image_operator_options
    all_options = MiniMagick::Tool::Convert.image_operators_options
    assert(all_options.length > 10)
    assert((['alpha', 'gamma', 'wave'] - all_options).empty?)
  end

  def test_image_sequence_operator_options
    all_options = MiniMagick::Tool::Convert.image_sequence_operators_options
    assert(all_options.length > 10)
    assert((['append', 'flatten', 'smush'] - all_options).empty?)
  end

  def test_available_options
    all_options = MiniMagick::Tool::Convert.available_options
    assert(all_options.length > 10)
    assert((['alpha', 'gamma', 'wave'] - all_options).empty?)
  end

  def test_option_group
    {
      'geometry' => 'image_operators',
      'depth' => 'image_settings',
      'colorspace' => 'image_settings',
      'append' => 'image_sequence_operators',
      'smush' => 'image_sequence_operators',
      'gamma' => 'image_operators'
    }.each_pair do |opt,group|
      assert_equal(group, MiniMagick::Tool::Convert.option_group(opt), "#{opt}")
    end
  end
end
