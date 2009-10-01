module Babushka
  class BaseHelper < PkgHelper
  class << self
    def pkg_type; :system end

    def prefix
      '/usr'
    end

  end
  end
end
