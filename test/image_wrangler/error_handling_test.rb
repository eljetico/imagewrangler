# frozen_string_literal: true

require_relative "../test_helper"

module ImageWrangler
  class ErrorHandlingTest < Minitest::Test
    def setup
    end

    def teardown
      clear_outfiles
    end

    def test_colorspace_profile_mismatch
      image = ImageWrangler::Image.new(raster_path("rgb_with_cmyk_profile.jpg"))
      assert_equal "RGB", image.colorspace
      assert_equal "Coated FOGRA39 (ISO 12647-2:2004)", image.icc_name

      component_list = to_rgb
      # transformer = image.transformer(component_list)
      # assert transformer.valid?
      refute image.transform(component_list)

      assert_equal "variant failed at index 0: colorspace/profile mismatch", image.errors.to_s
    end

    private

    def to_rgb
      profile = ImageWrangler::Profiles.AdobeRGB

      [
        {
          filepath: "/tmp/#{outfile_key}.to_rgb_100.jpg",
          options: {
            "geometry" => "100x100",
            "type" => "TrueColor",
            "profile" => "icc:#{profile}",
            "quality" => 80
          }
        }
      ]
    end
  end
end
