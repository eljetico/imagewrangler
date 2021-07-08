# frozen_string_literal: true

require_relative "../../../test_helper"

module ImageWrangler
  module Transformers
    module MiniMagick
      class VariantTest < Minitest::Test
        def setup
          @variant = ImageWrangler::Transformers::MiniMagick::Variant
        end

        def test_recipe_fails_with_empty_options
          subject = @variant.new({})
          subject.validate!
          refute subject.valid?
          assert subject.errors.include?(:options)
        end

        # rubocop:disable Layout/FirstHashElementIndentation
        def test_unrecognized_options_sets_error
          subject = @variant.new({
            options: {
              "qwerty" => "42",
              "dingbat" => "1970",
              "gamma" => "0.5"
            }
          })

          subject.validate!
          refute subject.valid?
          assert_equal(%w[qwerty dingbat], subject.unrecognized_options)
        end

        def test_array_value_options
          subject = @variant.new({
            options: {
                        "+profile" => %w[8BIMTEXT IPTC IPTCTEXT XMP]
            }
          })

          subject.validate!

          result = subject.grouped_options

          assert_equal 4, result["image_operators"].length
        end

        def test_filepath_supplied
          expected = "/path/to/file.jpg"

          subject = @variant.new({
                                   filepath: expected,
                                   options: {"crop" => "90x200+0+150"}
                                  })

          subject.validate!

          assert_equal expected, subject.filepath
        end

        def test_filepath_not_supplied
          subject = @variant.new({
            options: {"crop" => "90x200+0+150"}
          })

          subject.validate!

          assert subject.filepath.match(%r(\A/tmp/\w{6,}))
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def test_grouped_options_error
          subject = @variant.new({
            options: {
                        "crop" => "90x200+0+150",
                        "colorspace" => "RGB",
                        "gamma" => "0.5",
                        "sharpen" => "1x0.5"
            }
          })

          subject.validate!

          assert_equal(3, subject.grouped_options.keys.length)
          assert_equal(1, subject.grouped_options["image_settings"].length, "image_settings")
          assert_equal(2, subject.grouped_options["image_operators"].length, "image_operators")
          assert_equal(1, subject.grouped_options["image_sequence_operators"].length, "image_sequence_operators")
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disble Metrics/MethodLength
        def test_ordered_grouped_options
          subject = @variant.new({
            options: {
                        "crop" => "90x200+0+150",
                        "colorspace" => "RGB",
                        "gamma" => "0.5",
                        "sharpen" => "1x0.5"
            }
          })

          subject.validate!
          result = subject.ordered_options

          assert_equal "colorspace", result[0].clean_option
          assert_equal "crop", result[-1].clean_option
        end

        # Create an array of options and values for MiniMagick::Convert.merge!
        def test_merged_options
          subject = @variant.new({
                                    options: {
                                                "colorspace" => "RGB",
                                                "+profile" => %w[8BIMTEXT IPTC],
                                                "append" => nil
                                              }
                                  })

          subject.validate!

          expected = [
            "-colorspace",
            "RGB",

            "+profile",
            "8BIMTEXT",

            "+profile",
            "IPTC",

            "-append"
          ]

          assert_equal expected, subject.merged_options
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Layout/FirstHashElementIndentation
      end
    end
  end
end
