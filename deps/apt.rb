dep 'python-software-properties.managed' do
  provides 'add-apt-repository'
end

dep 'apt source', :uri, :release, :repo do
  requires 'python-software-properties.managed'
  uri.default!(Babushka::AptHelper.source_for_system)
  release.default!(Babushka.host.name)

  def present_in_file? filename
    # e.g. deb http://au.archive.ubuntu.com/ubuntu/ natty main restricted
    filename.p.read[/^deb\s+#{Regexp.escape(uri)}\s+#{release}\b.*\b#{repo}\b/]
  end

  met? {
    present_in_file?('/etc/apt/sources.list') or
      Dir.glob("/etc/apt/sources.list.d/*").any? {|f| present_in_file?(f) }
  }
  meet {
    sudo "add-apt-repository #{uri} #{release} #{repo}"
  }
  after {
    Babushka::AptHelper.update_pkg_lists "Updating apt lists to load #{uri}."
  }
end

dep 'ppa', :spec do
  requires 'python-software-properties.managed'
  def present_in_file? filename
    # e.g. deb http://ppa.launchpad.net/pitti/postgresql/ubuntu natty main
    filename.p.read[/^deb https?:\/\/.*\/#{spec.gsub(/^.*:/, '')}\/#{Babushka.host.flavour}/]
  end
  before {
    spec[/^\w+\:\w+/] or log_error("'#{spec}' doesn't look like 'ppa:something'.")
  }
  met? {
    present_in_file?('/etc/apt/sources.list') or
      Dir.glob("/etc/apt/sources.list.d/*").any? {|f| present_in_file?(f) }
  }
  meet {
    sudo "add-apt-repository #{spec}"
  }
  after {
    Babushka::AptHelper.update_pkg_lists "Updating apt lists to load #{spec}."
  }
end
