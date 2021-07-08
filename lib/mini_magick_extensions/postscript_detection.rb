# frozen_string_literal: true

module MiniMagick
  # Parse file as text to derive version, bounding box etc
  class Image
    PS_VERSION_REGEX = /.*?%
      !PS-Adobe-(\d\.\d)\s+?(?:EP[S|T]F*?-.*?)
      \W*?
    /x.freeze

    PS_BOUNDING_BOX_REGEX = /
      %%BoundingBox:
      \s(-?\d+)\s(-?\d+)\s(-?\d+)\s(-?\d+)
    /x.freeze

    PS_EOF_REGEX = /%%EOF/.freeze

    PS_LINE_SEP_REGEX = /[\r\n]+/.freeze

    OPTS = {}.freeze

    def postscript_version
      eps_metadata[:postscript_version]
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
    alias_method :vector_resize_density, :postscript_resize_density
    alias_method :vector_rescale_density, :postscript_resize_density

    def eps_metadata
      @eps_metadata ||= extract_eps_metadata
    end

    # rubocop:disable all
    def extract_eps_metadata
      return OPTS unless vector?
      return OPTS if pdf?

      begin
        f = StringIO.new to_blob

        lsep = _ps_get_line_sep(f)

        bounding_box_count = 0
        ps_version_found = false

        ps_version = nil
        actual_width = width
        actual_height = height

        f.each(sep = lsep) do |l|
          line = l.encode('UTF-8', 'binary', _ps_line_encode_opts)

          break if line.match(PS_EOF_REGEX)

          if (v_matches = line.match(PS_VERSION_REGEX))
            unless ps_version_found
              ps_version = v_matches[1].to_f
              ps_version_found = true
            end
          end

          if (bb_matches = line.match(PS_BOUNDING_BOX_REGEX))
            bounding_box_count += 1
            actual_width = bb_matches[3].to_i - bb_matches[1].to_i
            actual_height = bb_matches[4].to_i - bb_matches[2].to_i
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
    end
    # rubocop:enable all

    private

    def _ps_get_line_sep(str_blob)
      line = str_blob.gets.encode("UTF-8", "binary", _ps_line_encode_opts)
      lsep = line[PS_LINE_SEP_REGEX]
      str_blob.rewind
      lsep
    end

    def _ps_line_encode_opts
      {
        invalid: :replace,
        undef: :replace,
        replace: ""
      }
    end
  end
end
