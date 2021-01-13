# frozen_string_literal: true

require_relative 'mini_magick/variant'
require_relative 'mini_magick/option'
require_relative 'mini_magick/component_list'

module ImageWrangler
  module Transformers
    module MiniMagick
      class Transformer < ImageWrangler::Transformers::Transformer
        def instantiate_component_list(list)
          # rubocop:disable Layout/LineLength
          clist = ImageWrangler::Transformers::MiniMagick::ComponentList.new(list)
          # rubocop:enable Layout/LineLength
          clist.instantiate_variants
          clist
        end
      end
    end
  end
end
