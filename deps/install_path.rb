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

install_path 'writable install location' do
  requires 'install location exists', 'admins can sudo'
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

install_path 'install location exists' do
  met? { subpaths.all? {|path| File.directory?(install_prefix / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{install_prefix / path}'" } }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? install_prefix / 'bin' }
end
