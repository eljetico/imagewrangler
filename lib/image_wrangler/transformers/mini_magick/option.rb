# frozen_string_literal: true

module ImageWrangler
  module Transformers
    module MiniMagick
      class Option
        class << self
          def cleaned_option(option)
            option.sub(/\A[\-|\+]+?/, '')
          end

          def recognized?(key)
            clean_key = ImageWrangler::Transformers::MiniMagick::Option.cleaned_option(key)
            ImageWrangler::Transformers::MiniMagick::Option.available_options.include?(clean_key)
          end

          def available_options
            @@available_options ||= ::MiniMagick::Tool::Convert.available_options
          end
        end

        def initialize(key, value)
          @supplied_key = key
          @supplied_value = value
          # validate_key
        end

        def errors
          @error_handler
        end

        def clean_option
          @clean_option ||= ImageWrangler::Transformers::MiniMagick::Option.cleaned_option(@supplied_key)
        end

        def option_group
          @option_group ||= begin
            !recognized? ? 'unknown' : ::MiniMagick::Tool::Convert.option_group(clean_option)
          end
        end

        def plus_option?
          @plus_option ||= (@supplied_key.match(/\A\+/) ? true : false)
        end

        def recognized?
          @recognized = ImageWrangler::Transformers::MiniMagick::Option.recognized?(clean_option)
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
