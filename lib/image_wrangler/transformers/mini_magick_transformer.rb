# frozen_string_literal: true

require_relative 'mini_magick/variant'
require_relative 'mini_magick/option'
require_relative 'mini_magick/component_list'

module ImageWrangler
  module Transformers
    module MiniMagick
      # Transformer dedicated to MiniMagick
      class Transformer < ImageWrangler::Transformers::Transformer
        def instantiate_component_list(list)
          clist = ImageWrangler::Transformers::MiniMagick::ComponentList.new(list)
          clist.instantiate_variants
          clist
        end
      end
    end
  end
end
