
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
    define_var :dep_source, :default => (shell('git config github.user') || 'benhoskings'), :message => "Whose deps would you like to install (you can add others' later)"
  }
  met? {
    returning(!(source_count = shell('babushka sources -l').split("\n").reject {|l| l.starts_with? '#' }.length).zero?) do |result|
      log_ok "There #{source_count == 1 ? 'is' : 'are'} #{source_count} dep source#{'s' unless source_count == 1} set up." if result
    end
  }
  meet { shell "babushka sources -a '#{var :dep_source}' 'git://github.com/#{var(:dep_source)}/babushka-deps'", :log => true }
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

def subpaths
  %w[bin etc include lib sbin share share/doc var].concat(
    (1..9).map {|i| "share/man/man#{i}" }
  )
end

dep 'writable install location' do
  requires 'install location exists', 'admins can sudo'
  met? {
    writable, nonwritable = subpaths.partition {|path| File.writable?(var(:install_prefix) / path) }
    returning nonwritable.empty? do |result|
      log "Within #{var :install_prefix}, #{nonwritable.to_list} #{nonwritable.length == 1 ? "isn't" : "aren't"} writable by #{shell 'whoami'}." unless result
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
  met? { subpaths.all? {|path| File.directory?(var(:install_prefix) / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{var(:install_prefix) / path}'" } }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? var(:install_prefix) / 'bin' }
end
