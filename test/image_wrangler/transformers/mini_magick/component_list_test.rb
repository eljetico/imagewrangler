# frozen_string_literal: true

require_relative '../../../test_helper'

module ImageWrangler
  module Transformers
    module MiniMagick
      class ComponentListTest < Minitest::Test
        def setup
          @components = ImageWrangler::Transformers::MiniMagick::ComponentList
          @variant = ImageWrangler::Transformers::MiniMagick::Variant
        end

        def test_instantiates_with_empty_list
          subject = @components.new
          refute subject.instantiate_variants
        end

        def test_variant_handler
          subject = @components.new
          assert_equal @variant, subject.variant_handler
        end

        def test_bad_list
          subject = @components.new(bad_list)
          subject.instantiate_variants

          refute subject.valid?
          assert_equal(["variant 0: options unrecognized 'qwerty'"], subject.errors.full_messages)
        end

        private

        # rubocop:disable Metrics/MethodLength
        def bad_list
          [
            {
              filename: 'bad_recipe',
              options: {
                qwerty: true
              }
            },
            {
              filename: 'good_recipe',
              options: {
                gamma: 0.5,
                sharpen: '1x0.5',
                profile: 'icc:/path/to/profile.icc'
              }
            }
          ]
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
