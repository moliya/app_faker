require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class AppFakerHelper
      # class methods that you define here become available in your action
      # as `Helper::AppFakerHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the app_faker plugin helper!")
      end
    end
  end
end
