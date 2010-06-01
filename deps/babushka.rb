
dep 'babushka' do
  requires 'babushka in path', 'babushka up to date'
  define_var :install_prefix, :default => '/usr/local', :message => "Where would you like babushka installed"
  define_var :babushka_branch,
    :message => "Which branch would you like to update from?",
    :default => 'master',
    :choice_descriptions => {
      'master' => 'Standard-issue babushka',
      'next' => 'The development head -- slight risk of explosions'
    }
  setup {
    set :install_prefix, Babushka::Path.prefix if Babushka::Path.run_from_path?
  }
end

dep 'babushka up to date' do
  requires 'babushka repo clean', 'babushka update would fast forward'
  met? {
    in_dir(var(:install_prefix) / 'babushka') {
      shell("git rev-list ..origin/#{var :babushka_branch}").lines.to_a.empty?
    }
  }
  meet { in_dir(var(:install_prefix) / 'babushka') { shell("git merge origin/#{var :babushka_branch}", :log => true) } }
end

dep 'babushka update would fast forward' do
  requires 'babushka installed'
  met? {
    in_dir(var(:install_prefix) / 'babushka') {
      if !shell('git fetch')
        fail_because("Couldn't pull the latest code - check your internet connection.")
      else
        shell("git rev-list origin/#{var :babushka_branch}..").lines.to_a.empty? or
        fail_because("There are unpushed commits in #{var(:install_prefix) / 'babushka'}.")
      end
    }
  }
end

dep 'babushka repo clean' do
  requires 'babushka installed'
  met? {
    in_dir(var(:install_prefix) / 'babushka') {
      shell('git ls-files -m').lines.to_a.empty? or
      fail_because("There are local changes in #{var(:install_prefix) / 'babushka'}.")
    }
  }
end

dep 'babushka in path' do
  requires 'babushka installed'
  met? { which 'babushka' }
  meet {
    log_shell "Linking babushka into #{var(:install_prefix) / 'bin'}", %Q{ln -sf "#{var(:install_prefix) / 'babushka/bin/babushka.rb'}" "#{var(:install_prefix) / 'bin/babushka'}"}
  }
end

dep 'babushka installed' do
  requires 'ruby', 'git', 'writable install location', 'install location in path'
  setup { set :babushka_source, "git://github.com/benhoskings/babushka.git" }
  met? { git_repo?(var(:install_prefix) / 'babushka') }
  meet {
    in_dir var :install_prefix do |path|
      log_shell "Installing babushka to #{var(:install_prefix) / 'babushka'}", %Q{git clone "#{var :babushka_source}" ./babushka}
    end
  }
end

meta :install_path do
  template {
    helper :subpaths do
      %w[. bin etc include lib sbin share share/doc var].concat(
        (1..9).map {|i| "share/man/man#{i}" }
      )
    end
  }
end

install_path 'writable install location' do
  requires 'install location exists', 'admins can sudo'
  met? {
    writable, nonwritable = subpaths.partition {|path| File.writable_real?(var(:install_prefix) / path) }
    returning nonwritable.empty? do |result|
      log "Some directories within #{var :install_prefix} aren't writable by #{shell 'whoami'}." unless result
    end
  }
  meet {
    confirm "About to enable write access to #{var :install_prefix} for admin users - is that OK?" do
      subpaths.each {|subpath|
        sudo %Q{chgrp admin '#{var(:install_prefix) / subpath}'}
        sudo %Q{chmod g+w '#{var(:install_prefix) / subpath}'}
      }
    end
  }
end

install_path 'install location exists' do
  met? { subpaths.all? {|path| File.directory?(var(:install_prefix) / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{var(:install_prefix) / path}'" } }
end

# TODO this won't be necessary once vars can be passed as args.
install_path 'usr-local subpaths exist' do
  met? { subpaths.all? {|path| File.directory?('/usr/local' / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{'/usr/local' / path}'" } }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? var(:install_prefix) / 'bin' }
end
