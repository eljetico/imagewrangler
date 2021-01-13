# frozen_string_literal: true

module ImageWrangler
  module Transformers
    module MiniMagick
      # Process a supplied IM command line option
      class Option
        class << self
          def cleaned_option(option)
            option.sub(/\A[\-|\+]+?/, '')
          end

          def recognized?(key)
            # rubocop:disable Layout/LineLength
            clean_key = ImageWrangler::Transformers::MiniMagick::Option.cleaned_option(key)
            ImageWrangler::Transformers::MiniMagick::Option.available_options.include?(clean_key)
            # rubocop:enable Layout/LineLength
          end

          def available_options
            # rubocop:disable Style/ClassVars
            @@available_options ||= ::MiniMagick::Tool::Convert.available_options
            # rubocop:enable Style/ClassVars
          end
        end

        def initialize(key, value)
          @supplied_key = key
          @supplied_value = value
          @my_option = ImageWrangler::Transformers::MiniMagick::Option
        end

        def errors
          @error_handler
        end

        def clean_option
          @clean_option ||= @my_option.cleaned_option(@supplied_key)
        end

        def option_group
          @option_group ||= begin

            # rubocop:disable Layout/LineLength
            !recognized? ? 'unknown' : ::MiniMagick::Tool::Convert.option_group(clean_option)
            # rubocop:enable Layout/LineLength
          end
        end

        def plus_option?
          @plus_option ||= (@supplied_key.match(/\A\+/) ? true : false)
        end

        def recognized?
          @recognized = @my_option.recognized?(clean_option)
        end

        def to_s
          prefix = plus_option? ? '+' : '-'
          "#{prefix}#{clean_option}"
        end

        def value
          @supplied_value == '_x_' ? nil : @supplied_value
        end
      end
    end
  end
end
