meta :src do
  accepts_list_for :source
  accepts_list_for :extra_source
  accepts_list_for :provides, :basename
  accepts_value_for :prefix, '/usr/local'
  accepts_value_for :jobs, Babushka.host.cpus

  accepts_block_for(:preconfigure) {
    if './configure'.p.exists?
      true # No preconfigure needed
    elsif !'./configure.in'.p.exists? && !'./configure.ac'.p.exists?
      true # Not pre-configurable
    else
      log_shell "autoconf", "autoconf"
    end
  }
  accepts_block_for(:configure) { log_shell "configure", default_configure_command }
  accepts_list_for :configure_env
  accepts_list_for :configure_args

  accepts_block_for(:build) { log_shell "build", "make -j #{jobs}" }
  accepts_block_for(:install) { Babushka::SrcHelper.install_src! 'make install' }
  accepts_block_for(:postinstall)

  accepts_block_for(:process_source) {
    invoke(:preconfigure) and
    invoke(:configure) and
    invoke(:build) and
    invoke(:install) and
    invoke(:postinstall)
  }

  def default_configure_command
    "#{configure_env.map(&:to_s).join} ./configure --prefix=#{prefix} #{configure_args.map(&:to_s).join(' ')}"
  end

  template {
    requires_when_unmet 'build tools', 'curl.bin'
    met? { in_path?(provides) }
    meet {
      extra_source.each {|uri|
        Babushka::Resource.extract(uri)
      }
      source.each {|uri|
        Babushka::Resource.extract(uri) {|archive|
          invoke(:process_source)
        }
      }
    }
  }
end
