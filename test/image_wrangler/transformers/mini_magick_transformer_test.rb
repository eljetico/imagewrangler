# frozen_string_literal: true

require_relative '../../test_helper'
require 'image_wrangler'

class ImageWrangler::Transformers::MiniMagickTransformerTest < Minitest::Test
  OUTFILE_KEY = 'imagewrangler'

  def setup
    @transformer = ImageWrangler::Transformers::MiniMagick::Transformer
  end

  def teardown
    Dir.glob("/tmp/#{OUTFILE_KEY}.*").each do |file|
      File.unlink(file)
    end
  end

  def test_instantiates_with_menu
    image = ImageWrangler::Image.new(raster_path('valid_jpg.jpg'))
    menu = menu_simple_resize

    subject = @transformer.new(image, menu)

    assert subject.valid?
    assert subject.process

    rendered = ImageWrangler::Image.new(menu[0][:filepath])
    assert_equal 100, rendered.height

    rendered = ImageWrangler::Image.new(menu[1][:filepath])
    assert_equal 200, rendered.height
  end

  private

  def menu_simple_resize
    [
      {
        filepath: "/tmp/#{OUTFILE_KEY}.lo_res_100.jpg",
        options: {
          "geometry" => '100x100',
          "type" => 'TrueColor',
          "auto-orient" => nil,
        }
      },
      {
        filepath: "/tmp/#{OUTFILE_KEY}.lo_res_200.jpg",
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
        filepath: "/tmp/#{OUTFILE_KEY}.grayscale_to_rgb_100.jpg",
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
        filepath: "/tmp/#{OUTFILE_KEY}.cmyk_to_rgb_100.jpg",
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
