module Babushka
  class BaseHelper < PkgHelper
  class << self
    def pkg_type; :unknown end
    def manager_key; :unknown end
    def manager_dep; nil end

    private

    def _install! pkgs, opts
      raise DepDefiner::UnmeetableDep, "I don't know how to use the package manager on this system."
    end

    def _has? pkg
      raise DepDefiner::UnmeetableDep, "I don't know how to use the package manager on this system."
    end
  end
  end
end
