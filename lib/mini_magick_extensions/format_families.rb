# frozen_string_literal: true

module MiniMagick
  RASTER_FORMATS = %w[BMP JPEG JPF JP2 PAM PNG WEBP GIF HEIF TIFF].freeze
  VECTOR_FORMATS = %w[PDF PS EPT EPS SVG].freeze
  POSTSCRIPT_FORMATS = %w[PDF EPT EPS PS].freeze

  PERMITTED_EXTENSIONS = {
    'BMP' => ['.bmp'],
    'EPT' => ['.eps', '.ept'],
    'EPS' => ['.eps', '.ept'],
    'JPEG' => ['.jpg', '.jpeg'],
    'JPF' => ['.jp2', '.j2k', '.jpf', '.jpx', '.jpm', '.mj2'],
    'PAM' => ['.webp'],
    'PNG' => ['.png'],
    'WEBP' => ['.webp'],
    'GIF' => ['.gif'],
    'HEIF' => [
      '.heif',
      '.heifs',
      '.heic',
      '.heics',
      '.avci',
      '.avcs',
      '.avif',
      '.avifs'
    ],
    'TIFF' => ['.tif', '.tiff'],
    'PS' => ['.eps', '.ept'],
    'PDF' => ['.pdf'],
    'SVG' => ['.svg']
  }.freeze

  # Extends MiniMagick::Image class with custom functionality
  class Image
    def image_type
      return 'raster' if raster?

      return 'vector' if vector?

      'unknown'
    end

    def raster?
      RASTER_FORMATS.include?(type.upcase)
    end

    def pdf?
      type.upcase.match(/PDF/) ? true : false
    end

    def postscript?
      POSTSCRIPT_FORMATS.include?(type.upcase)
    end

    def vector?
      VECTOR_FORMATS.include?(type.upcase)
    end

    def valid_extensions
      PERMITTED_EXTENSIONS.fetch(type.upcase, [])
    end
  end
end
