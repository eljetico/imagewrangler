# frozen_string_literal: true

module ImageWrangler
  module Transformers
    module MiniMagick
      # Parse, validate and persist the given list of recipes
      # `menu` is an array of recipe configurations suitable for
      # ImageWrangler::Transformers::MiniMagick::Recipe instances
      class Menu
        def initialize(menu)
          @error_handler = ImageWrangler::Errors.new
          @recipes = instantiate_recipes(menu)
        end

        def errors
          @error_handler
        end

        def instantiate_recipes(menu)
          recipes = []
          Array(menu).compact.each_with_index do |config, index|
            recipe = ImageWrangler::Transformers::MiniMagick::Recipe.new(config)
            unless recipe.valid?
              errors.add(:recipe, "#{index}: #{recipe.errors.full_messages}")
            else
              recipes.push(recipe)
            end
          end
          recipes
        end

        def recipes
          @recipes # may need to order them if cascading?
        end

        def valid?
          errors.empty?
        end
      end
    end
  end
end
