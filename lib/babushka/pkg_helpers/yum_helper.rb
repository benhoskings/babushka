module Babushka
  class YumHelper < PkgHelper
  class << self
    def pkg_type; :rpm end
    def pkg_cmd; pkg_binary end
    def pkg_binary; "yum" end
    def manager_key; :yum end
  end
  end
end
