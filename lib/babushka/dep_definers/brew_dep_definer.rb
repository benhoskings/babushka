module Babushka
  class BrewDepDefiner < PkgDepDefiner

    private

    def pkg_manager
      BrewHelper
    end

  end
end
