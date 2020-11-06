# frozen_string_literal: true

require_relative '../../../test_helper'
require 'image_wrangler'

# rubocop:disable Metrics/ClassLength
class ImageWrangler::Transformers::MiniMagick::MenuTest < Minitest::Test
  def setup

  end

  def test_menu_errors
    subject = ImageWrangler::Transformers::MiniMagick::Menu.new(bad_recipe)
    refute subject.valid?
    assert subject.errors.include?(:recipe)
  end

  def bad_recipe
    [
      {
        filename: 'bad_recipe',
        options: {
          qwerty: true
        }
      },
      {
        filename: 'good_recipe',
        options: {
          gamma: 0.5,
          sharpen: '1x0.5',
          profile: 'icc:/path/to/profile.icc'
        }
      }
    ]
  end
end
