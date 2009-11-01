
dep 'babushka' do
  requires 'babushka in path', 'dep source'
  define_var :install_prefix, :default => '/usr/local', :message => "Where would you like babushka installed"
end

dep 'babushka in path' do
  requires 'babushka installed'
  met? { which 'babushka' }
  meet {
    log_shell "Linking babushka into #{var(:install_prefix) / 'bin'}", %Q{ln -sf "#{var(:install_prefix) / 'babushka/bin/babushka.rb'}" "#{var(:install_prefix) / 'bin/babushka'}"}
  }
end

dep 'dep source' do
  requires 'babushka in path'
  setup {
    define_var :dep_source, :default => shell('git config github.user'), :message => "Whose deps would you like to install (you can add others' later)"
  }
  met? {
    returning(!(source_count = Babushka::Source.count).zero?) do |result|
      log_ok "There #{source_count == 1 ? 'is' : 'are'} #{source_count} dep source#{'s' unless source_count == 1} set up." if result
    end
  }
  meet { Babushka::Source.add! var(:dep_source), "git://github.com/#{var(:dep_source)}/babushka-deps" }
end

dep 'babushka installed' do
  requires 'ruby', 'git', 'writable install location', 'install location in path'
  set :babushka_source, "git://github.com/benhoskings/babushka.git"
  met? { File.exists? var(:install_prefix) / 'babushka/bin/babushka.rb' }
  meet {
    in_dir var :install_prefix do |path|
      log_shell "Installing babushka to #{var(:install_prefix) / 'babushka'}", %Q{git clone "#{var :babushka_source}" ./babushka}
    end
  }
end

dep 'writable install location' do
  requires 'install location exists', 'admins can sudo'
  met? {
    returning File.writable? var(:install_prefix) do |result|
      log "#{var :install_prefix} isn't writable by #{shell 'whoami'}."
    end
  }
  meet {
    confirm "About to enable write access to #{var :install_prefix} for admin users - is that OK?" do
      sudo %Q{chgrp -R admin '#{var :install_prefix}'}
      sudo %Q{chmod -R g+w '#{var :install_prefix}'}
    end
  }
end

dep 'install location exists' do
  met? { File.directory? var(:install_prefix) / 'bin' }
  meet { sudo "mkdir -p '#{var(:install_prefix) / 'bin'}'" }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? var(:install_prefix) / 'bin' }
end
