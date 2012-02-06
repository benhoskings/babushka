module Babushka
  class UnknownPkgHelper < PkgHelper
  class << self
    def pkg_type; :unknown end
    def manager_key; :unknown end
    def manager_dep; nil end

    private

    def _install! pkgs, opts
      raise UnmeetableDep, "This system's package manager (if it has one) isn't supported."
    end

    def _has? pkg
      raise UnmeetableDep, "This system's package manager (if it has one) isn't supported."
    end
  end
  end
end
