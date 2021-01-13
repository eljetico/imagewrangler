# frozen_string_literal: true

require_relative '../test_helper'

module ImageWrangler
  class ProfilesTest < Minitest::Test
    def setup; end

    def test_srgb
      subject = ImageWrangler::Profiles.sRGB
      assert File.exist?(subject)
    end

    def test_cmyk
      subject = ImageWrangler::Profiles.CMYK
      assert File.exist?(subject)
    end

    def test_adobergb
      subject = ImageWrangler::Profiles.AdobeRGB
      assert File.exist?(subject)
    end
  end
end
