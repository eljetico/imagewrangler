# frozen_string_literal: true

module MiniMagick
  BASE_POSTSCRIPT = %w[EPI EPS EPSF EPSI EPS2 EPS3 EPT PS PS2 PS3].freeze
  RASTER_FORMATS = %w[BMP JPEG JPF JP2 PAM PNG WEBP GIF HEIF TIFF].freeze

  POSTSCRIPT_FORMATS = BASE_POSTSCRIPT + %w[PDF].freeze
  VECTOR_FORMATS = POSTSCRIPT_FORMATS + %w[SVG].freeze

  PERMITTED_EXTENSIONS = {
    "BMP" => [".bmp"],
    "EPT" => [".eps", ".ept"],
    "EPS" => [".eps", ".ept"],
    "JPEG" => [".jpg", ".jpeg"],
    "JPF" => [".jp2", ".j2k", ".jpf", ".jpx", ".jpm", ".mj2"],
    "PAM" => [".webp"],
    "PNG" => [".png"],
    "WEBP" => [".webp"],
    "GIF" => [".gif"],
    "HEIF" => [
      ".heif",
      ".heifs",
      ".heic",
      ".heics",
      ".avci",
      ".avcs",
      ".avif",
      ".avifs"
    ],
    "TIFF" => [".tif", ".tiff"],
    "PS" => [".eps", ".ept"],
    "PDF" => [".pdf"],
    "SVG" => [".svg"]
  }.freeze

  # Extends MiniMagick::Image class with custom functionality
  class Image
    def image_type
      return "raster" if raster?

      return "vector" if vector?

      "unknown"
    end

    def eps?
      @eps ||= BASE_POSTSCRIPT.include?(_type_upcased)
    end

    def raster?
      @raster ||= RASTER_FORMATS.include?(_type_upcased)
    end

    def pdf?
      _type_upcased == "PDF"
    end

    def postscript?
      @postscript ||= POSTSCRIPT_FORMATS.include?(_type_upcased)
    end

    def vector?
      @vector ||= VECTOR_FORMATS.include?(_type_upcased)
    end

    def valid_extensions
      PERMITTED_EXTENSIONS.fetch(_type_upcased, EMPTY_ARRAY)
    end

    def _type_upcased
      @_type_upcased ||= type.upcase
    end
  end
end
