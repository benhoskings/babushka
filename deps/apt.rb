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
    present_in_file?('/etc/apt/sources.list')
  }
  meet {
    sudo "add-apt-repository #{uri} #{release} #{repo}"
  }
  after {
    Babushka::AptHelper.update_pkg_lists "Updating apt lists to load #{uri}."
  }
end
