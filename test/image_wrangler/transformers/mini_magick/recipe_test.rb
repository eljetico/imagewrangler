# frozen_string_literal: true

require_relative '../../../test_helper'
require 'image_wrangler'

# rubocop:disable Metrics/ClassLength
class ImageWrangler::Transformers::MiniMagick::RecipeTest < Minitest::Test
  def setup

  end

  def test_recipe_fails_with_empty_options
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({})
    refute subject.valid?
    assert subject.errors.include?(:options)
  end

  def test_unrecognized_options_sets_error
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      options: {
        'qwerty' => '42',
        'dingbat' => '1970',
        'gamma' => '0.5'
      }
    })

    refute subject.valid?
    assert_equal(['qwerty', 'dingbat'], subject.unrecognized_options)
  end

  def test_array_value_options
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      options: {
        '+profile' => %w(8BIMTEXT IPTC IPTCTEXT XMP),
      }
    })

    result = subject.grouped_options

    assert_equal 4, result['image_operators'].length
  end

  def test_filepath_supplied
    expected = '/path/to/file.jpg'

    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      filepath: expected,
      options: { 'crop' => '90x200+0+150' }
    })

    assert_equal expected, subject.filepath
  end

  def test_filepath_not_supplied
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      options: { 'crop' => '90x200+0+150' }
    })

    # Just checking for minimum 8 chars
    assert subject.filepath.match(/\A\/tmp\/\w{6,}/)
  end

  def test_grouped_options_error
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      options: {
        'crop' => '90x200+0+150',
        'colorspace' => 'RGB',
        'gamma' => '0.5',
        'sharpen' => '1x0.5'
      }
    })

    assert_equal(3, subject.grouped_options.keys.length)
    assert_equal(1, subject.grouped_options['image_settings'].length, "image_settings")
    assert_equal(2, subject.grouped_options['image_operators'].length, "image_operators")
    assert_equal(1, subject.grouped_options['image_sequence_operators'].length, "image_sequence_operators")
  end

  def test_ordered_grouped_options
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      options: {
        'crop' => '90x200+0+150',
        'colorspace' => 'RGB',
        'gamma' => '0.5',
        'sharpen' => '1x0.5'
      }
    })

    result = subject.ordered_options

    assert_equal 'colorspace', result[0].clean_option
    assert_equal 'crop', result[-1].clean_option
  end

  # Create an array of options and values for MiniMagick::Convert.merge!
  def test_merged_options
    subject = ImageWrangler::Transformers::MiniMagick::Recipe.new({
      options: {
        'colorspace' => 'RGB',
        '+profile' => %w(8BIMTEXT IPTC),
        'append' => nil
      }
    })

    expected = [
      '-colorspace',
      'RGB',

      '+profile',
      '8BIMTEXT',

      '+profile',
      'IPTC',

      '-append'
    ]

    assert_equal expected, subject.merged_options
  end

end
