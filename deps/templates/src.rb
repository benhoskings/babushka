meta :src do
  accepts_list_for :source
  accepts_list_for :extra_source
  accepts_list_for :provides, :default_name
  accepts_list_for :prefix, '/usr/local'

  def default_name
    Babushka::VersionOf.new name
  end

  accepts_block_for :preconfigure

  accepts_block_for(:configure) { log_shell "configure", default_configure_command }
  accepts_list_for :configure_env
  accepts_list_for :configure_args

  accepts_block_for(:build) { log_shell "build", "make" }
  accepts_block_for(:install) { Babushka::SrcHelper.install_src! 'make install' }

  accepts_block_for(:process_source) {
    call_task(:preconfigure) and
    call_task(:configure) and
    call_task(:build) and
    call_task(:install)
  }

  template {
    helper :default_configure_command do
      "#{configure_env.map(&:to_s).join} ./configure --prefix=#{prefix.first} #{configure_args.map(&:to_s).join(' ')}"
    end

    requires 'build tools'
    internal_setup { setup_source_uris }
    met? { provided? }
    meet { process_sources { call_task :process_source } }
  }
end
