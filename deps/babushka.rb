
dep 'babushka' do
  requires 'babushka in path'
  define_var :install_prefix, :default => '/usr/local', :message => "Where would you like babushka installed"
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
  set :babushka_source, "git://github.com/benhoskings/babushka.git"
  met? { File.exists? var(:install_prefix) / 'babushka/bin/babushka.rb' }
  meet {
    in_dir var :install_prefix do |path|
      log_shell "Installing babushka to #{var(:install_prefix) / 'babushka'}", %Q{git clone "#{var :babushka_source}" ./babushka}
    end
  }
end

dep 'writable install location' do
  requires 'admins can sudo'
  met? { File.writable? var(:install_prefix) }
  meet {
    confirm "About to enable write access to #{var :install_prefix} for admin users - is that OK?" do
      sudo %Q{chgrp -R admin '#{var :install_prefix}'}
      sudo %Q{chmod -R g+w '#{var :install_prefix}'}
    end
  }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? var(:install_prefix) / 'bin' }
end
