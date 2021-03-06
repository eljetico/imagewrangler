# frozen_string_literal: true

module ImageWrangler
  # Methods for scaling calculations
  module ScalingHelper
    def scaling_factor(target_pixel_area, width, height)
      current_area = width * height
      return 1.0 if current_area == target_pixel_area

      # Using a fudge factor here to help ensure resulting factor meets or
      # exceeds desired area when multiplied.
      scf = Math.sqrt(target_pixel_area / (width * height).to_f) + 0.0005
      scf.round(4)
    end

    def dimensions_for_target_pixel_area(target_pixel_area)
      scf = scaling_factor(target_pixel_area, width, height)
      ImageWrangler::Dimensions.new((width * scf).ceil, (height * scf).ceil)
    end
  end
end
