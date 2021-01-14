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
            # rubocop:disable Style/RedundantSelf
            options = self.send("#{grp}_options".to_sym)
            # rubocop:enable Style/RedundantSelf
            return grp if options.include?(option)
          end

          nil
        end

        # rubocop:disable Style/ClassVars
        def available_options
          @@available_options ||= [
            # rubocop:disable Style/RedundantSelf
            self.image_settings_options,
            self.image_operators_options,
            self.image_sequence_operators_options
            # rubocop:enable Style/RedundantSelf
          ].flatten.uniq
        end
        # rubocop:enable Style/ClassVars

        def image_settings_options
          # rubocop:disable Style/ClassVars
          @@image_settings_options ||= begin
            MiniMagick::Tool::Convert.extract_tool_options
          end
          # rubocop:enable Style/ClassVars
        end

        def image_operators_options
          # rubocop:disable Style/ClassVars
          @@image_operators_options ||= begin
            MiniMagick::Tool::Convert.extract_tool_options('Image Operators')
          end
          # rubocop:enable Style/ClassVars
        end

        def image_sequence_operators_options
          # rubocop:disable Style/ClassVars
          @@image_sequence_operators_options ||= begin
            # rubocop:disable Layout/LineLength
            MiniMagick::Tool::Convert.extract_tool_options('Image Sequence Operators')
            # rubocop:enable Layout/LineLength
          end
          # rubocop:enable Style/ClassVars
        end

        def tool_help
          # rubocop:disable Style/ClassVars
          @@tool_help ||= begin
            # rubocop:disable Style/SymbolProc
            MiniMagick::Tool::Convert.new(whiny: false) do |b|
              b.help
            end
            # rubocop:enable Style/SymbolProc
          end
          # rubocop:enable Style/ClassVars
        end

        def extract_tool_options(option_group = 'Image Settings')
          tool_help = MiniMagick::Tool::Convert.tool_help

          # Take option group to first double newline
          # rubocop:disable Layout/LineLength
          tool_help.match(/\n#{option_group}\:\n(.*?)(?:\n\n)/mi)[1].split("\n").map do |line|
            option = line.strip.split(/\s+/)[0]
            # Remove hyphen in performant way (better than 'sub' apparently)
            option[0] = ''
            option
          end
          # rubocop:enable Layout/LineLength
        end
      end
    end
  end
end
