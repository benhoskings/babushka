module Babushka
  class BrewDepDefiner < PkgDepDefiner

    private

    def chooser
      :brew
    end
    def pkg_manager
      BrewHelper
    end

  end
end
