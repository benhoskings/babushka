meta :fhs do
  def subpaths
    %w[. bin etc include lib sbin share share/doc var].concat(
      (1..9).map {|i| "share/man/man#{i}" }
    )
  end
  def install_prefix
    var(:install_path).p.parent
  end
end

dep 'writable.fhs' do
  requires 'layout.fhs'
  requires_when_unmet 'admins can sudo'
  met? {
    writable, nonwritable = subpaths.partition {|path| File.writable_real?(install_prefix / path) }
    nonwritable.empty?.tap {|result|
      log "Some directories within #{install_prefix} aren't writable by #{shell 'whoami'}." unless result
    }
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

dep 'layout.fhs' do
  met? { subpaths.all? {|path| File.directory?(install_prefix / path) } }
  meet { sudo "mkdir -p #{subpaths.map {|path| "'#{install_prefix / path}'" }.join(' ')}" }
end

dep 'install location in path', :template => 'external' do
  met? { ENV['PATH'].split(':').include? install_prefix / 'bin' }
end
