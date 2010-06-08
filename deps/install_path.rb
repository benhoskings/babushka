def subpaths
  %w[. bin etc include lib sbin share share/doc var].concat(
    (1..9).map {|i| "share/man/man#{i}" }
  )
end

dep 'writable install location' do
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

dep 'install location exists' do
  met? { subpaths.all? {|path| File.directory?(var(:install_prefix) / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{var(:install_prefix) / path}'" } }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? var(:install_prefix) / 'bin' }
end
