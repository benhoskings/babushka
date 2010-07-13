meta :install_path do
  template {
    helper :subpaths do
      %w[. bin etc include lib sbin share share/doc var].concat(
        (1..9).map {|i| "share/man/man#{i}" }
      )
    end
    helper :install_prefix do
      var(:install_path).p.parent
    end
  }
end

dep 'writable.install_path' do
  requires 'existing.install_path', 'admins can sudo'
  met? {
    writable, nonwritable = subpaths.partition {|path| File.writable_real?(install_prefix / path) }
    returning nonwritable.empty? do |result|
      log "Some directories within #{install_prefix} aren't writable by #{shell 'whoami'}." unless result
    end
  }
  meet {
    confirm "About to enable write access to #{install_prefix} for admin users - is that OK?" do
      subpaths.each {|subpath|
        sudo %Q{chgrp admin '#{install_prefix / subpath}'}
        sudo %Q{chmod g+w '#{install_prefix / subpath}'}
      }
    end
  }
end

dep 'existing.install_path' do
  met? { subpaths.all? {|path| File.directory?(install_prefix / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{install_prefix / path}'" } }
end

# TODO this won't be required once we can pass vars around
dep 'usr-local.install_path' do
  met? { subpaths.all? {|path| File.directory?('/usr/local' / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{'/usr/local' / path}'" } }
end

dep 'install location in path', :template => 'external' do
  met? { ENV['PATH'].split(':').include? install_prefix / 'bin' }
end
