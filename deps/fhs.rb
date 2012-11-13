meta :fhs do
  def subpaths
    %w[. bin etc include lib sbin share share/doc var].concat(
      (1..9).map {|i| "share/man/man#{i}" }
    )
  end
end

dep 'writable.fhs', :_path do
  requires 'layout.fhs'.with(_path)
  requires_when_unmet 'admins can sudo'
  met? {
    _, nonwritable = subpaths.partition {|subpath| File.writable_real?(_path / subpath) }
    nonwritable.empty?.tap {|result|
      log "Some directories within #{_path} aren't writable by #{shell 'whoami'}." unless result
    }
  }
  meet {
    confirm "About to enable write access to #{_path} for admin users - is that OK?" do
      subpaths.each {|subpath|
        sudo %Q{chgrp admin '#{_path / subpath}'}
        sudo %Q{chmod g+w '#{_path / subpath}'}
      }
    end
  }
end

dep 'layout.fhs', :_path do
  met? { subpaths.all? {|subpath| File.directory?(_path / subpath) } }
  meet { sudo "mkdir -p #{subpaths.map {|subpath| "'#{_path / subpath}'" }.join(' ')}" }
end
