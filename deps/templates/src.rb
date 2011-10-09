meta :src do
  accepts_list_for :source
  accepts_list_for :extra_source
  accepts_list_for :provides, :basename
  accepts_value_for :prefix, '/usr/local'

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

  accepts_block_for(:build) { log_shell "build", "make" }
  accepts_block_for(:install) { Babushka::SrcHelper.install_src! 'make install' }
  accepts_block_for(:postinstall)

  accepts_block_for(:process_source) {
    call_task(:preconfigure) and
    call_task(:configure) and
    call_task(:build) and
    call_task(:install) and
    call_task(:postinstall)
  }

  def default_configure_command
    "#{configure_env.map(&:to_s).join} ./configure --prefix=#{prefix} #{configure_args.map(&:to_s).join(' ')}"
  end

  template {
    requires 'build tools', 'curl.managed'
    prepare { setup_source_uris }
    met? { in_path?(provides) }
    meet { process_sources { call_task :process_source } }
  }
end
