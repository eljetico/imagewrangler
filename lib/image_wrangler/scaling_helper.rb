# frozen_string_literal: true

module ImageWrangler
  # Methods for scaling calculations
  module ScalingHelper
    def downscale_to_pixelarea(target_pixelarea, filepath)
      # Only raster images
      return false unless raster?

      scf = scaling_factor(target_pixelarea)
      max_dim = [(scf * width).to_i, (scf * height).to_i].max

      transform = {
        filepath: filepath,
        options: {
          "quality" => 99,
          "format" => file_format,
          "auto-orient" => nil,
          "geometry" => "#{max_dim}x#{max_dim}"
        }
      }

      transformer = transformer([transform])

      if transformer.valid? && transformer.process
        return File.exist?(filepath)
      end

      # Errors are asserted on the Image instance
      false
    end

    def scaling_factor(target_pixel_area, w = width, h = height)
      current_area = w * h
      return 1.0 if current_area == target_pixel_area

      downscaling = target_pixel_area < current_area

      # Unless downscaling, we need to meet or exceed the required target area.
      # Add a fudge factor to accomplish this but omit if we're downscaling
      scf = Math.sqrt(target_pixel_area / (w * h).to_f) + (downscaling ? 0 : 0.0005)
      downscaling ? scf : scf.round(4)
    end

    def dimensions_for_fixed_side(fixed_side)
      sf = fixed_side.to_f / [width, height].max
      ImageWrangler::Dimensions.new((width * sf).ceil, (height * sf).ceil)
    end

    def dimensions_for_target_pixel_area(target_pixel_area)
      scf = scaling_factor(target_pixel_area, width, height)
      ImageWrangler::Dimensions.new((width * scf).ceil, (height * scf).ceil)
    end

    def pixel_area_for_fixed_side(fixed_side)
      sf = fixed_side.to_f / [width, height].max
      (sf * width).ceil * (sf * height).ceil
    end
  end
end
