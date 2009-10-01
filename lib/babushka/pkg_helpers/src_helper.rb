module Babushka
  class SrcHelper < PkgHelper
  class << self
    def pkg_type; :src end

    def prefix
      '/usr/local'
    end

  end
  end
end
