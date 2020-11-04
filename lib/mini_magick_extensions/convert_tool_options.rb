# frozen_string_literal: true

module MiniMagick
  class Tool
    class Convert
      class << self
        def option_group(option)
          [
            'image_settings',
            'image_operators',
            'image_sequence_operators'
          ].each do |grp|
            options = self.send("#{grp}_options".to_sym)
            return grp if options.include?(option)
          end

          nil
        end

        def available_options
          @@available_options ||= [
            self.image_settings_options,
            self.image_operators_options,
            self.image_sequence_operators_options
          ].flatten.uniq
        end

        def image_settings_options
          @@image_settings_options ||= begin
            MiniMagick::Tool::Convert.extract_tool_options
          end
        end

        def image_operators_options
          @@image_operators_options ||= begin
            MiniMagick::Tool::Convert.extract_tool_options('Image Operators')
          end
        end

        def image_sequence_operators_options
          @@image_sequence_operators_options ||= begin
            MiniMagick::Tool::Convert.extract_tool_options('Image Sequence Operators')
          end
        end

        def tool_help
          @@tool_help ||= begin
            MiniMagick::Tool::Convert.new(whiny: false) do |b|
              b.help
            end
          end
        end

        def extract_tool_options(option_group = 'Image Settings')
          tool_help = MiniMagick::Tool::Convert.tool_help

          # Take option group to first double newline
          tool_help.match(/\n#{option_group}\:\n(.*?)(?:\n\n)/mi)[1].split("\n").map{|line|
            option = line.strip.split(/\s+/)[0]
            option[0] = '' # remove hyphen (performant over `sub` etc)
            option
          }
        end
      end
    end
  end
end
