# frozen_string_literal: true

require_relative "../test_helper"

module ImageWrangler
  class ScalingHelperTest < Minitest::Test
    DummyImage = Struct.new(:width, :height) do
      include ScalingHelper
    end

    def setup
    end

    def test_downscale_to_pixelarea
      filepath = raster_path("valid_jpg.jpeg")
      im = ImageWrangler::Image.new(filepath)
      target_pixelarea = (im.pixelarea / 1.5).to_i
      outfile = "/tmp/out.jpg"

      assert im.downscale_to_pixelarea(target_pixelarea, outfile)

      new_im = ImageWrangler::Image.new(outfile)
      assert(new_im.pixelarea <= target_pixelarea)
    end

    def test_upscaling_factor
      subject = DummyImage.new(nil, nil)
      target_px_area = 5_230_000
      assert_equal 3.2413, subject.scaling_factor(target_px_area, 990, 503)
    end

    # No rounding when downscaling as we want to be as close as possible
    def test_downscaling_factor
      subject = DummyImage.new(nil, nil)
      target_px_area = 1_168_561 # 1080x1080
      assert_equal 0.3120578204969927, subject.scaling_factor(target_px_area, 3000, 4000)
    end

    def test_pixel_area_for_fixed_side
      subject = DummyImage.new(4048, 3032)
      assert_equal 43200, subject.pixel_area_for_fixed_side(240)
    end

    def test_upscaling_factor_volume
      skip("Enable when volume testing")
      subject = DummyImage.new(nil, nil)
      target_px_area = 5_230_000

      dims = (100..2286)
      dims.each do |w|
        dims.each do |h|
          scf = subject.scaling_factor(target_px_area, w, h)
          new_w = (w * scf).ceil
          new_h = (h * scf).ceil
          assert((new_w * new_h) >= target_px_area, "#{w} x #{h} @ #{scf} failed")
        end
      end
    end

    def test_downscaling_factor_volume
      skip("Enable when volume testing")
      subject = DummyImage.new(nil, nil)
      target_px_area = 1_168_561

      dims = (2000..5000)
      dims.each do |w|
        dims.each do |h|
          scf = subject.scaling_factor(target_px_area, w, h)
          new_w = (w * scf).ceil
          new_h = (h * scf).ceil
          assert((new_w * new_h) >= target_px_area, "#{w} x #{h} @ #{scf} failed")
        end
      end
    end

    def test_dimensions_for_target_pixel_area
      subject = DummyImage.new(990, 503)
      result = subject.dimensions_for_target_pixel_area(5_230_000)
      assert_equal(3209, result.width)
      assert_equal(1631, result.height)
    end

    def test_dimensions_for_fixed_side
      subject = DummyImage.new(990, 503)
      result = subject.dimensions_for_fixed_side(240)
      assert_equal([240, 122], result.to_a)
    end
  end
end
