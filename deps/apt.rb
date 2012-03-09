dep 'apt source', :uri, :release, :repo do
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
    append_to_file "deb #{uri} #{release} #{repo}", '/etc/apt/sources.list.d/babushka.list', :sudo => true
  }
  after {
    Babushka::AptHelper.update_pkg_lists "Updating apt lists to load #{uri}."
  }
end

dep 'ppa', :spec do
  def spec_path
    spec.to_s.gsub(/^.*:/, '')
  end
  def present_in_file? filename
    # e.g. deb http://ppa.launchpad.net/pitti/postgresql/ubuntu natty main
    filename.p.read[/^deb https?:\/\/[^\/]+\/#{spec_path}\/#{Babushka.host.flavour}\b/]
  end
  before {
    spec[/^\w+\:\w+/] or log_error("'#{spec}' doesn't look like 'ppa:something'.")
  }
  met? {
    present_in_file?('/etc/apt/sources.list') or
      Dir.glob("/etc/apt/sources.list.d/*").any? {|f| present_in_file?(f) }
  }
  meet {
    append_to_file "deb http://ppa.launchpad.net/#{spec_path}/ubuntu #{Babushka.host.name} main",
      '/etc/apt/sources.list.d/babushka.list'
  }
  after {
    Babushka::AptHelper.update_pkg_lists "Updating apt lists to load #{spec}."
  }
end
