module Babushka
  class YumHelper < PkgHelper
  class << self
    def pkg_type; :rpm end
    def pkg_cmd; pkg_binary end
    def pkg_binary; "yum" end
    def manager_key; :yum end

    private

    def _has? pkg_name
      # Some example output, with 'wget' installed:
      #   fedora-13:  'wget.x86_64  1.12-2.fc13       @fedora'
      #   centos-5.5: 'wget.x86_64  1.11.4-2.el5_4.1  installed'
      final_word = failable_shell("#{pkg_binary} list '#{pkg_name}'").stdout[/[^\s]+$/] || ''
      (final_word == 'installed') || final_word.starts_with?('@')
    end

  end
  end
end
