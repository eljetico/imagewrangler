# frozen_string_literal: true

require_relative "../../test_helper"
require "image_wrangler"

module ImageWrangler
  module Transformers
    # rubocop:disable Metrics/ClassLength
    class TransformerTest < Minitest::Test
      OUTFILE_KEY = "imagewrangler"

      def setup
        @transformer = ImageWrangler::Transformers::MiniMagick::Transformer
      end

      def teardown
        Dir.glob("/tmp/#{OUTFILE_KEY}.*").each do |file|
          File.unlink(file)
        end
      end

      def test_instantiate_menu_not_implemented
        image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))

        assert_raises NotImplementedError do
          ImageWrangler::Transformers::Transformer.new(image, {})
        end
      end

      # rubocop:disable Metrics/AbcSize
      def test_transformer_can_accept_optional_args
        image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
        component_list = simple_resize_components
        transformer = image.transformer(component_list, {cascade: true})
        assert transformer.is_a?(ImageWrangler::Image::DEFAULT_TRANSFORMER)
        assert transformer.options[:cascade]

        transformer = image.transformer(component_list)
        assert transformer.is_a?(ImageWrangler::Image::DEFAULT_TRANSFORMER)
        assert transformer.options.key?(:errors)
      end

      # rubocop:disable Metrics/MethodLength
      def test_transformer_can_cascade_components
        image = ImageWrangler::Image.new(raster_path("valid_jpg.jpg"))
        component_list = simple_resize_components
        transformer = image.transformer(component_list, {cascade: true})
        assert transformer.options[:cascade]
        assert transformer.valid?
        assert transformer.process

        render_one = transformer.components[0]
        assert_equal 200, render_one.height
        assert_equal(render_one.checksum, "b0630a34c11024dc352f9c5a9d4014c0")
        assert_equal(render_one.filename, "#{OUTFILE_KEY}.lo_res_200.jpg")
        assert(render_one.mtime.is_a?(Time))

        # Source for first render is our main image ^
        source_image = transformer.components[0].source_image
        assert_equal image.filepath, source_image.filepath

        render_two = transformer.components[1]
        assert_equal 100, render_two.height

        # Source for second render is the previously rendered variant ^
        source_image = transformer.components[1].source_image
        assert_equal render_one.filepath, source_image.filepath
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      private

      # rubocop:disable Metrics/MethodLength
      def simple_resize_components
        [
          {
            filepath: "/tmp/#{OUTFILE_KEY}.lo_res_200.jpg",
            options: {
              "geometry" => "200x200",
              "type" => "TrueColor",
              "auto-orient" => nil
            }
          },
          {
            filepath: "/tmp/#{OUTFILE_KEY}.lo_res_100.jpg",
            options: {
              "geometry" => "100x100",
              "type" => "TrueColor",
              "auto-orient" => nil
            }
          }
        ]
      end

      def menu_grayscale_to_rgb
        profile = profile_path("sRGB-IEC61966-2.1.icc")

        [
          {
            filepath: "/tmp/#{OUTFILE_KEY}..grayscale_to_rgb_100.jpg",
            options: {
              "geometry" => "100x100",
              "type" => "TrueColor",
              "profile" => "icc:#{profile}",
              "quality" => 80
            }
          }
        ]
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      def menu_cmyk_to_rgb
        # cmyk_profile = profile_path('USWebCoatedSWOP.icc')
        rgb_profile = profile_path("sRGB-IEC61966-2.1.icc")

        [
          {
            filepath: "/tmp/#{OUTFILE_KEY}.cmyk_to_rgb_100.jpg",
            options: {
              "geometry" => "100x100",
              "type" => "TrueColor",
              "profile" => [rgb_profile],
              "quality" => 80
            }
          }
        ]
      end
      # rubocop:enable Metrics/MethodLength

      def profile_path(icc_name)
        File.expand_path(
          File.join(
            File.dirname(__FILE__), "..", "..", "resources", "color_profiles",
            icc_name
          )
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
