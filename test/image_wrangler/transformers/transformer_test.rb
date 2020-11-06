# frozen_string_literal: true

require_relative '../../test_helper'
require 'image_wrangler'

class ImageWrangler::Transformers::TransformerTest < Minitest::Test
  def setup
  end

  def test_instantiate_menu_not_implemented
    image = ImageWrangler::Image.new(raster_path('valid_jpg.jpg'))

    assert_raises NotImplementedError do
      ImageWrangler::Transformers::Transformer.new(image, {})
    end
  end

  private

  def menu_simple_resize
    [
      {
        filepath: '/tmp/pickle.lo_res_100.jpg',
        options: {
          "geometry" => '100x100',
          "type" => 'TrueColor',
          "auto-orient" => nil,
        }
      },
      {
        filepath: '/tmp/pickle.lo_res_200.jpg',
        options: {
          "geometry" => '200x200',
          "type" => 'TrueColor',
          "auto-orient" => nil
        }
      }
    ]
  end

  def menu_grayscale_to_rgb
    profile = profile_path('sRGB-IEC61966-2.1.icc')

    [
      {
        filepath: '/tmp/pickle.grayscale_to_rgb_100.jpg',
        options: {
          "geometry" => '100x100',
          "type" => 'TrueColor',
          "profile" => "icc:#{profile}",
          "quality" => 80
        }
      }
    ]
  end

  def menu_cmyk_to_rgb
    cmyk_profile = profile_path('USWebCoatedSWOP.icc')
    rgb_profile = profile_path('sRGB-IEC61966-2.1.icc')

    [
      {
        filepath: '/tmp/pickle.cmyk_to_rgb_100.jpg',
        options: {
          "geometry" => '100x100',
          "type" => 'TrueColor',
          "profile" => [rgb_profile],
          "quality" => 80
        }
      }
    ]
  end

  def profile_path(icc_name)
    File.expand_path(File.join(
      File.dirname(__FILE__), '..', '..', 'resources', 'color_profiles',
      icc_name
    ))
  end
end
