module Babushka
  class GemDepDefiner < PkgDepDefiner

    def installs obj
      payload[:installs] = {:gem => obj}
    end

    private

    def pkg_manager
      GemHelper
    end
  end
end
