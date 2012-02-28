meta :ppa do
  accepts_value_for :adds
  template {
    requires 'python-software-properties.managed'
    met? {
      Dir.glob("/etc/apt/sources.list.d/*").any? {|f|
        f.p.read[Regexp.new('https?://' + adds.gsub(':', '.*') + '/ubuntu ')]
      }
    }
    before {
      adds[/^\w+\:\w+/] or log_error("'#{adds}' doesn't look like 'ppa:something'.")
    }
    meet {
      sudo "sudo add-apt-repository #{adds}"
    }
    after {
      Babushka.host.pkg_helper.update_pkg_lists "Updating apt lists to load #{adds}."
    }
  }
end
