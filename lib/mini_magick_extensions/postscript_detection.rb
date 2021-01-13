# frozen_string_literal: true

module MiniMagick
  # Check for visual corruption of supplied image
  class Image
    def postscript_version
      eps_metadata.fetch(:postscript_version)
    end

    # Density required for 20mp by default
    # EPS are 72 PPI
    def postscript_resize_density(target_pixels = 20_000_000, density = 72)
      return nil unless vector?

      height = eps_metadata.fetch(:actual_height, 0)
      width = eps_metadata.fetch(:actual_width, 0)

      return density if (height + width).zero?

      pixel_area = height * width
      correction_factor = 1.025
      scaling_factor = Math.sqrt(target_pixels * correction_factor / pixel_area)

      (density * scaling_factor).ceil
    end
    alias vector_resize_density postscript_resize_density
    alias vector_rescale_density postscript_resize_density

    def eps_metadata
      @eps_metadata ||= extract_eps_metadata
    end

    # rubocop:disable Metrics/AbcSize
    def extract_eps_metadata
      return {} unless vector?
      return {} if pdf?

      version_regex = /\A.*?\%\!PS-Adobe-(\d\.\d)\s+?(?:EP[S|T]F*?-.*?)\W*?\z/x
      bounds_regex  = /\%\%BoundingBox:\s(-?\d+)\s(-?\d+)\s(-?\d+)\s(-?\d+)/

      begin
        # need to get separator First
        lsep = "\n"
        f = StringIO.new to_blob
        line = f.gets.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        lsep = line[/[\r\n]+/]

        f.rewind

        bounding_box_count = 0
        ps_version_found = false

        ps_version = nil
        actual_width = width
        actual_height = height

        # File.open(file_path, 'r:UTF-8').each(sep = lsep) do |l|
        f.each(sep = lsep) do |l|
          line = l.encode('UTF-8', 'binary', {
            invalid: :replace,
            undef: :replace,
            replace: ''
          })

          break if line.match(/\A\%\%EOF/)

          if (v_matches = line.match(version_regex))
            unless ps_version_found
              ps_version = v_matches[1].to_f
              ps_version_found = true
            end
          end

          if (bb_matches = line.match(bounds_regex))
            bounding_box_count += 1
            @actual_width = bb_matches[3].to_i - bb_matches[1].to_i
            @actual_height = bb_matches[4].to_i - bb_matches[2].to_i
          end
        end

        if bounding_box_count > 1
          raise MiniMagick::Error, 'More than one bounding box encountered'
        end

        {
          actual_height: actual_height,
          actual_width: actual_width,
          postscript_version: ps_version
        }
      ensure
        f.close
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
