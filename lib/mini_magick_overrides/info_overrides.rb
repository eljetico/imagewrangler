# frozen_string_literal: true

module MiniMagick
  class Image
    # Override MiniMagick raw method to quiet noisy identify calls
    class Info
      def raw(value)
        @info["raw:#{value}"] ||= identify do |b|
          b.quiet if suppress_warnings && noisy_property?(value)
          b.format(value)
        end
      end

      def noisy_property?(value)
        # standard:disable Performance/RegexpMatch
        value.match(/(8BIM:|Decoded)/i) ? true : false # standard:disable Performance/RedundantMatch
        # standard:enable Performance/RegexpMatch
      end

      def suppress_warnings
        MiniMagick.quiet_warnings
      end
    end
  end
end
