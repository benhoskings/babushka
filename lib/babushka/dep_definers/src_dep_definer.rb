module Babushka
  class SrcDepDefiner < BaseDepDefiner

    accepts_list_for :source
    accepts_list_for :provides, :default_name
    accepts_list_for :prefix, '/usr/local'

    accepts_block_for :preconfigure

    accepts_block_for(:configure) { shell default_configure_command }
    accepts_list_for :configure_env
    accepts_list_for :configure_args

    accepts_block_for(:build) { shell "make" }
    accepts_block_for(:install) { pkg_manager.install_src! 'make install' }

    accepts_block_for(:process_source) {
      call_task(:preconfigure) and
      call_task(:configure) and
      call_task(:build) and
      call_task(:install)
    }

    def pkg_manager
      SrcHelper
    end

    def process
      requires 'build tools'
      internal_setup {
        setup_source_uris
      }
      met? {
        present, missing = provides.partition {|cmd_name| cmd_dir(cmd_name) }

        returning missing.empty? do
          log "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing from your PATH." unless missing.empty?
        end
      }
      meet {
        process_sources { call_task(:process_source, :log => false) }
      }
    end


    private

    def default_name
      VersionOf.new name
    end

  end
end
