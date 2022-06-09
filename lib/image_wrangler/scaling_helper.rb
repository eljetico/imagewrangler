# frozen_string_literal: true

module ImageWrangler
  # Methods for scaling calculations
  module ScalingHelper
    def downscale_to_pixelarea(target_pixel_area, filepath)
      # Only raster images
      return false unless raster?

      new_dimensions = dimensions_for_target_pixel_area(target_pixel_area)
      max_dim = new_dimensions.max

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

      scaling_factor_two(target_pixel_area, current_area)
    end

    # Original, unreliable scaling
    def scaling_factor_one(target_pixel_area, current_area)
      downscaling = target_pixel_area < current_area

      # Unless downscaling, we need to meet or exceed the required target area.
      # Add a fudge factor to accomplish this but omit if we're downscaling
      scf = Math.sqrt(target_pixel_area / (w * h).to_f) + (downscaling ? 0 : 0.0005)
      downscaling ? scf : scf.round(4)
    end

    # Simplest method, no rounding
    def scaling_factor_two(target_pixel_area, current_area)
      Math.sqrt(target_pixel_area / current_area.to_f) # no rounding
    end

    def dimensions_for_fixed_side(fixed_side)
      sf = fixed_side.to_f / [width, height].max
      ImageWrangler::Dimensions.new((width * sf).ceil, (height * sf).ceil)
    end

    # If downscaling, we need to be <= target, so use .to_i when rounding
    # If upscaling, we need to be >= target, so use .ceil when rounding
    def dimensions_for_target_pixel_area(target_pixel_area, w = width, h = height)
      current_area = w * h
      return ImageWrangler::Dimensions.new(w, h) if current_area == target_pixel_area

      downscaling = current_area > target_pixel_area
      scf = scaling_factor_two(target_pixel_area, current_area)

      rounding = downscaling ? :to_i : :ceil
      ImageWrangler::Dimensions.new((w * scf).send(rounding), (h * scf).send(rounding))
    end

    def pixel_area_for_fixed_side(fixed_side)
      sf = fixed_side.to_f / [width, height].max
      (sf * width).ceil * (sf * height).ceil
    end
  end
end
