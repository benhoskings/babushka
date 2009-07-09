module Babushka
  class GemDepDefiner < PkgDepDefiner

    private

    def chooser
      :gem
    end
    def pkg_manager
      GemHelper
    end

  end
end
