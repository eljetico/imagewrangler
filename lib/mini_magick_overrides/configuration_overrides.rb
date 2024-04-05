# frozen_string_literal: true

module MiniMagick
  # Extend configuration to handle supplied option for suppressing warnings
  module Configuration
    def quiet_warnings=(boolean)
      @quiet_warnings = boolean
    end

    def quiet_warnings
      return instance_variable_get(:@quiet_warnings) if instance_variable_defined?("@quiet_warnings")

      false
    end
  end
end
