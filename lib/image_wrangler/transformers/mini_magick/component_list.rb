# frozen_string_literal: true

module ImageWrangler
  module Transformers
    module MiniMagick
      # Module-specific component list handler
      class ComponentList < ImageWrangler::Transformers::ComponentList
        def variant_handler
          ImageWrangler::Transformers::MiniMagick::Variant
        end
      end
    end
  end
end
