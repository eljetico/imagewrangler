# frozen_string_literal: true

require_relative "../../test_helper"
require "image_wrangler"

module ImageWrangler
  module Transformers
    # rubocop:disable Metrics/ClassLength
    class MiniMagickTransformerTest < Minitest::Test
      def setup
        # MiniMagick.logger.level = Logger::DEBUG
        @transformer = ImageWrangler::Transformers::MiniMagick::Transformer
      end

      def teardown
        clear_outfiles
      end

      def test_invalid_with_empty_component_list
        image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
        subject = @transformer.new(image, [])

        refute subject.valid?
        assert_equal("component_list cannot be empty", image.errors.full_messages[0])
      end

      # rubocop:disable Metrics/AbcSize
      def test_simple_resize
        image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
        menu = menu_simple_resize
        subject = @transformer.new(image, menu)

        assert subject.valid?
        assert subject.process

        rendered = ImageWrangler::Image.new(menu[0][:filepath])
        assert_equal 100, rendered.height

        rendered = ImageWrangler::Image.new(menu[1][:filepath])
        assert_equal 200, rendered.height
      end

      def test_remove_outfile_on_profile_error
        image = ImageWrangler::Image.new(raster_path("grayscale.jpg"))

        menu = menu_grayscale_to_rgb
        menu[0][:options]["profile"] = "icc:/path/to/missing_profile.icc"

        subject = @transformer.new(image, menu)

        refute subject.process
        refute File.exist?(menu[0][:filepath])

        assert_match(/variant failed at index 0/i, image.errors.full_messages[0])
      end

      def test_conversion_with_rgb_profile
        image = ImageWrangler::Image.new(raster_path("grayscale.jpg"))
        menu = menu_grayscale_to_rgb
        subject = @transformer.new(image, menu)

        assert subject.process

        rendered = ImageWrangler::Image.new(menu[0][:filepath])
        assert_equal 100, rendered.width
        assert_equal "RGB", rendered.colorspace
        assert_equal 80, rendered.quality
      end

      def test_conversion_cmyk_to_rgb
        menu = menu_cmyk_to_rgb
        image = ImageWrangler::Image.new(raster_path("cmyk_no_profile.jpg"))
        subject = @transformer.new(image, menu)

        assert subject.valid?
        assert subject.process

        rendered = ImageWrangler::Image.new(menu[0][:filepath])
        assert_equal 100, rendered.width
        assert_equal "RGB", rendered.colorspace
        assert_equal 80, rendered.quality
      end
      # rubocop:enable Metrics/AbcSize

      private

      # rubocop:disable Metrics/MethodLength
      def menu_simple_resize
        [
          {
            filepath: "/tmp/#{outfile_key}.lo_res_100.jpg",
            options: {
              "geometry" => "100x100",
              "type" => "TrueColor",
              "auto-orient" => nil
            }
          },
          {
            filepath: "/tmp/#{outfile_key}.lo_res_200.jpg",
            options: {
              "geometry" => "200x200",
              "type" => "TrueColor",
              "auto-orient" => nil
            }
          }
        ]
      end

      def menu_grayscale_to_rgb
        [
          {
            filepath: "/tmp/#{outfile_key}.grayscale_to_rgb_100.jpg",
            options: {
              "geometry" => "100x100",
              "type" => "TrueColor",
              "profile" => "icc:#{ImageWrangler::Profiles.sRGB}",
              "quality" => 80
            }
          }
        ]
      end

      def menu_cmyk_to_rgb
        [
          {
            filepath: "/tmp/#{outfile_key}.cmyk_to_rgb_100.jpg",
            options: {
              "geometry" => "100x100",
              "type" => "TrueColor",
              "profile" => [ImageWrangler::Profiles.sRGB],
              "quality" => 80
            }
          }
        ]
      end
      # rubocop:enable Metrics/MethodLength

      def profile_path(icc_name)
        File.join(ImageWrangler.root, "resources", "color_profiles", icc_name)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
