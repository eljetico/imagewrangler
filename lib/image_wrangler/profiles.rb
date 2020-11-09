# frozen_string_literal: true

module ImageWrangler
  module Profiles
    def self.path
      @@path ||= File.join(ImageWrangler.root, 'resources', 'color_profiles')
    end

    def self.sRGB
      @@sRGB ||= File.join(self.path, 'sRGB-IEC61966-2.1.icc')
    end

    def self.AdobeRGB
      @@AdobeRGB ||= File.join(self.path, 'AdobeRGB1998.icc')
    end

    def self.CMYK
      @@CMYK ||= File.join(self.path, 'USWebCoatedSWOP.icc')
    end
  end
end
