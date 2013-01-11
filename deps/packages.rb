dep 'curl.bin'

dep 'gettext.lib'

dep 'nodejs.src', :version do
  deprecated! "2013-03-10", :method_name => "'#{name}'", :callpoint => false, :instead => "the 'nodejs.bin' dep"
  requires 'nodejs.bin'
  met? {
    in_path? 'node >= 0.6.12'
  }
end

dep 'nodejs.bin' do
  installs {
    via :apt, 'nodejs', 'nodejs-dev'
    otherwise 'node'
  }
  provides 'node >= 0.6.12'
  after {
    # Trigger the creation of npm's global package dir, which it can't run without.
    shell!('npm --version')
  }
end

dep 'sudo.bin'
