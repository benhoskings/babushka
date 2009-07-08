module Babushka
  class GemDepDefiner < PkgDepDefiner

    private

    def pkg_manager
      GemHelper
    end
  end
end
