# frozen_string_literal: true

require_relative 'mini_magick/variant'
require_relative 'mini_magick/option'
require_relative 'mini_magick/component_list'

module ImageWrangler
  module Transformers
    module MiniMagick
      class Transformer < ImageWrangler::Transformers::Transformer
        def instantiate_component_list(list)
          component_list = ImageWrangler::Transformers::MiniMagick::ComponentList.new(list)
          component_list.instantiate_variants
          component_list
        end
      end
    end
  end
end
