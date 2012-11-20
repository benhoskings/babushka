dep 'apt source', :uri, :release, :repo do
  uri.default!(Babushka::AptHelper.source_for_system)
  release.default!(Babushka.host.name)

  def present_in_file? filename
    # e.g. deb http://au.archive.ubuntu.com/ubuntu/ natty main restricted
    src = Regexp.escape(uri).sub('//archive', '//(?:..\.)?archive') << '(?:/)?'
    filename.p.exists? &&
    filename.p.read[/^deb\s+#{src}\s+#{release}\b.*\b#{repo}\b/]
  end

  met? {
    present_in_file?('/etc/apt/sources.list') or
      Dir.glob("/etc/apt/sources.list.d/*").any? {|f| present_in_file?(f) }
  }
  meet {
    '/etc/apt/sources.list.d/babushka.list'.p.append("deb #{uri} #{release} #{repo}\n")
  }
  after {
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
