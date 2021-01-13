# frozen_string_literal: true

module ImageWrangler
  # Container for ICC profile resources
  module Profiles
    # rubocop:disable Style/ClassVars
    def self.path
      @@path ||= File.join(ImageWrangler.root, 'resources', 'color_profiles')
    end

    # rubocop:disable Naming/MethodName
    def self.sRGB
      @@sRGB ||= File.join(path, 'sRGB-IEC61966-2.1.icc')
    end

    def self.AdobeRGB
      @@AdobeRGB ||= File.join(path, 'AdobeRGB1998.icc')
    end

    def self.CMYK
      @@CMYK ||= File.join(path, 'USWebCoatedSWOP.icc')
    end
    # rubocop:enable Naming/MethodName
  end
  # rubocop:enable Style/ClassVars
end
