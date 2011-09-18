meta :fhs do
  def subpaths
    %w[. bin etc include lib sbin share share/doc var].concat(
      (1..9).map {|i| "share/man/man#{i}" }
    )
  end
end

dep 'writable.fhs', :path do
  requires Dep('layout.fhs').with(path)
  requires_when_unmet 'admins can sudo'
  met? {
    _, nonwritable = subpaths.partition {|subpath| File.writable_real?(path / subpath) }
    nonwritable.empty?.tap {|result|
      log "Some directories within #{path} aren't writable by #{shell 'whoami'}." unless result
    }
  }
  meet {
    confirm "About to enable write access to #{path} for admin users - is that OK?" do
      subpaths.each {|subpath|
        sudo %Q{chgrp admin '#{path / subpath}'}
        sudo %Q{chmod g+w '#{path / subpath}'}
      }
    end
  }
end

dep 'layout.fhs', :path do
  met? { subpaths.all? {|subpath| File.directory?(path / subpath) } }
  meet { sudo "mkdir -p #{subpaths.map {|subpath| "'#{path / subpath}'" }.join(' ')}" }
end
