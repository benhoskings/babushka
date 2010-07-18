module Babushka
  class YumHelper < PkgHelper
  class << self
    def pkg_type; :rpm end
    def pkg_cmd; pkg_binary end
    def pkg_binary; "yum" end
    def manager_key; :yum end

    private

    def _has? pkg_name
      failable_shell("#{pkg_binary} list '#{pkg_name}'").stdout.val_for(/^#{pkg_name}\.(\w+)/).ends_with?('installed')
    end

    def pkg_update_timeout
      3600 * 24 # 1 day
    end

  end
  end
end
