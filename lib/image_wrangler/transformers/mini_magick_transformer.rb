# frozen_string_literal: true

require_relative 'mini_magick/menu'
require_relative 'mini_magick/recipe'
require_relative 'mini_magick/option'

module ImageWrangler
  module Transformers
    module MiniMagick
      class Transformer < ImageWrangler::Transformers::Transformer

        def instantiate_menu(menu)
          ImageWrangler::Transformers::MiniMagick::Menu.new(menu)
        end

        def process_recipe(recipe, index)
          begin
            tool = ::MiniMagick::Tool::Convert.new
            # Use the validated image filepath
            tool << @image.filepath

            # There are a few ways to do this in MiniMagick, using merge! is
            # the most flexible although requires some care when constructing
            # the options/values
            tool.merge! recipe.merged_options

            # Finally, add the output filepath
            tool << recipe.filepath

            tool.call do |stdout, stderr, status|
              unless status.zero?
                raise StandardError, stderr
              end

              # Gather data about the resulting file
              inspect_result(recipe, index)
            end
          rescue StandardError => e
            new_message = "failed at index #{index}: #{e.message}"
            ensure_outfile_removed(recipe.filepath)
            errors.add(:recipe, new_message)
          end
        end

        def inspect_result(recipe, index)

        end
      end
    end
  end
end
