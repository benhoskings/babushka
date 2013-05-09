dep 'apt source', :uri, :release, :repo, :uri_matcher do
  uri.default!(Babushka::AptHelper.source_for_system)
  release.default!(Babushka.host.name)
  uri_matcher.default!(Babushka::AptHelper.source_matcher_for_system)

  met? {
    shell('grep -h \^deb /etc/apt/sources.list /etc/apt/sources.list.d/*').split("\n").any? {|l|
      # e.g. deb http://au.archive.ubuntu.com/ubuntu/ natty main restricted
      l[/^deb\s+#{uri_matcher}\s+#{release}\b.*\b#{repo}\b/]
    }
  }
  meet {
    '/etc/apt/sources.list.d/babushka.list'.p.append("deb #{uri} #{release} #{repo}\n")

    Babushka::AptHelper.update_pkg_lists "Updating apt lists to load #{uri}."
  }
end

dep 'ppa', :spec do
  requires 'python-software-properties.bin'
  def spec_name
    log_error("'#{spec}' doesn't look like 'ppa:something'.") unless spec[/^ppa\:\w+/]
    spec.to_s.sub(/^ppa\:/, '')
  end
  def ppa_release_file
    # This may be hardcoded to some extent, but I'm calling YAGNI on it for now.
    "ppa.launchpad.net_#{spec_name.gsub('/', '_')}_ubuntu_dists_#{Babushka.host.name}_Release"
  end
  met? {
    ('/var/lib/apt/lists/' / ppa_release_file).exists?
  }
  meet {
    log_shell "Adding #{spec}", "add-apt-repository '#{spec}'", :spinner => true
    log_shell "Updating apt lists to load #{spec}.", "apt-get update"
  }
end

dep 'python-software-properties.bin' do
  provides 'add-apt-repository'
end
