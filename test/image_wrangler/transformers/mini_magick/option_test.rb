# frozen_string_literal: true

require_relative '../../../test_helper'
require 'image_wrangler'

module ImageWrangler
  module Transformers
    module MiniMagick
      class OptionTest < Minitest::Test
        def setup
          @klass = ImageWrangler::Transformers::MiniMagick::Option
        end

        def test_invalid_option
          subject = @klass.new('qwerty', [])
          refute subject.recognized?
        end

        def test_plus_option
          subject = @klass.new('+repage', [])
          assert subject.plus_option?

          subject = @klass.new('repage', [])
          refute subject.plus_option?
        end

        def test_option_group
          subject = @klass.new('geometry', [])
          assert_equal 'image_operators', subject.option_group
        end

        def test_empty_value
          subject = @klass.new('append', nil)
          assert_equal '-append', subject.to_s
          assert_nil subject.value
        end
      end
    end
  end
end
