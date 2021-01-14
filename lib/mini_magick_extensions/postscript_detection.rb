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

    def version_regex
      /\A.*?\%\!PS-Adobe-(\d\.\d)\s+?(?:EP[S|T]F*?-.*?)\W*?\z/x
    end

    def bounds_regex
      /\%\%BoundingBox:\s(-?\d+)\s(-?\d+)\s(-?\d+)\s(-?\d+)/
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def extract_eps_metadata
      return {} unless vector?
      return {} if pdf?

      begin
        f = StringIO.new to_blob
        # rubocop:disable Layout/FirstHashElementIndentation
        line = f.gets.encode('UTF-8', 'binary', {
          invalid: :replace,
          undef: :replace,
          replace: ''
        })
        # rubocop:enable Layout/FirstHashElementIndentation

        lsep = line[/[\r\n]+/]

        f.rewind

        bounding_box_count = 0
        ps_version_found = false

        ps_version = nil
        actual_width = width
        actual_height = height

        # rubocop:disable Lint/UselessAssignment
        f.each(sep = lsep) do |l|
          # rubocop:disable Layout/FirstHashElementIndentation
          line = l.encode('UTF-8', 'binary', {
            invalid: :replace,
            undef: :replace,
            replace: ''
          })
          # rubocop:enable Layout/FirstHashElementIndentation

          break if line.match(/\A\%\%EOF/)

          if (v_matches = line.match(version_regex))
            unless ps_version_found
              ps_version = v_matches[1].to_f
              ps_version_found = true
            end
          end

          # rubocop:disable Style/Next
          if (bb_matches = line.match(bounds_regex))
            bounding_box_count += 1
            @actual_width = bb_matches[3].to_i - bb_matches[1].to_i
            @actual_height = bb_matches[4].to_i - bb_matches[2].to_i
          end
          # rubocop:enable Style/Next
        end
        # rubocop:enable Lint/UselessAssignment

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
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
