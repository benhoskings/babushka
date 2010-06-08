def subpaths
  %w[. bin etc include lib sbin share share/doc var].concat(
    (1..9).map {|i| "share/man/man#{i}" }
  )
end

dep 'writable install location' do
  requires 'install location exists', 'admins can sudo'
  met? {
    writable, nonwritable = subpaths.partition {|path| File.writable_real?(var(:install_path).parent / path) }
    returning nonwritable.empty? do |result|
      log "Some directories within #{var(:install_path).parent} aren't writable by #{shell 'whoami'}." unless result
    end
  }
  meet {
    confirm "About to enable write access to #{var(:install_path).parent} for admin users - is that OK?" do
      subpaths.each {|subpath|
        sudo %Q{chgrp admin '#{var(:install_path).parent / subpath}'}
        sudo %Q{chmod g+w '#{var(:install_path).parent / subpath}'}
      }
    end
  }
end

dep 'install location exists' do
  met? { subpaths.all? {|path| File.directory?(var(:install_path).parent / path) } }
  meet { subpaths.each {|path| sudo "mkdir -p '#{var(:install_path).parent / path}'" } }
end

ext 'install location in path' do
  met? { ENV['PATH'].split(':').include? var(:install_path).parent / 'bin' }
end
