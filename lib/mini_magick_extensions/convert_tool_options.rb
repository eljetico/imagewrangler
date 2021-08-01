# frozen_string_literal: true

module MiniMagick
  class Tool
    # Extend Convert tool to sequence options correctly
    class Convert
      class << self
        def option_group(option)
          %w[
            image_settings image_operators image_sequence_operators
          ].each do |grp|
            # standard:disable Style/RedundantSelf
            options = self.send(:"#{grp}_options")
            # standard:enable Style/RedundantSelf
            return grp if options.include?(option)
          end

          nil
        end

        def available_options
          @@available_options ||= [
            image_settings_options,
            image_operators_options,
            image_sequence_operators_options
          ].flatten.uniq
        end

        def image_settings_options
          @@image_settings_options ||= _convert_tool.extract_tool_options
        end

        def image_operators_options
          @@image_operators_options ||= _convert_tool.extract_tool_options("Image Operators")
        end

        def image_sequence_operators_options
          @@image_sequence_operators_options ||= _convert_tool.extract_tool_options("Image Sequence Operators")
        end

        def tool_help
          # standard:disable Style/RedundantBegin
          @@tool_help ||= begin
            _convert_tool.new(whiny: false) do |b|
              b.help
            end
          end
          # standard:enable Style/RedundantBegin
        end

        def extract_tool_options(option_group = "Image Settings")
          tool_help = _convert_tool.tool_help

          # Take option group to first double newline
          tool_help.match(/\n#{option_group}:\n(.*?)(?:\n\n)/mi)[1].split("\n").map do |line|
            option = line.strip.split(/\s+/)[0]
            # Remove hyphen in performant way (better than 'sub' apparently)
            option[0] = ""
            option
          end
        end

        def _convert_tool
          MiniMagick::Tool::Convert
        end
      end
    end
  end
end
