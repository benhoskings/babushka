module Babushka
  class YumHelper < PkgHelper
  class << self
    def pkg_type; :rpm end
    def pkg_cmd; pkg_binary end
    def pkg_binary; "yum" end
    def manager_key; :yum end

    private

    def has_pkg? pkg_name
      # Some example output, with 'wget' installed:
      #   fedora-13:  'wget.x86_64  1.12-2.fc13       @fedora'
      #   centos-5.5: 'wget.x86_64  1.11.4-2.el5_4.1  installed'
      raw_shell("#{pkg_binary} list -q '#{pkg_name}'").stdout.split("\n").select {|line|
        line[/^#{Regexp.escape(pkg_name.to_s)}\.\w+\b/] # e.g. wget.x86_64
      }.any? {|match|
        final_word = match[/[^\s]+$/] || ''
        (final_word == 'installed') || final_word.starts_with?('@')
      }
    end

  end
  end
end
