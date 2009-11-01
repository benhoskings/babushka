require 'uri'

module Babushka
  class SrcDepRunner < BaseDepRunner

    private

    def parse_uris
      @uris = source.map {|uri| URI.parse uri.to_s }
    end

    def do_it_live
      get_sources and process_sources
    end

    # multi-URI methods

    def get_sources
      in_build_dir {
        @uris.all? {|uri|
          handle_source uri
        }
      }
    end

    def process_sources
      @uris.all? {|uri|
        in_build_dir(build_path_for(uri)) {
          call_task(:preconfigure) and
          call_task(:configure) and
          call_task(:build) and
          call_task(:install)
        }
      }
    end


    # single-URI methods

    def handle_source uri
      send({
        'http' => :get_source,
        'ftp' => :get_source,
        'git' => :git
      }[uri.scheme] || :unsupported_scheme, uri)
    end

    def default_configure_command
      "#{configure_env.map(&:to_s).join} ./configure --prefix=#{prefix.first} #{configure_args.map(&:to_s).join}"
    end

    def call_task task_name
      if (task_block = send(task_name)).nil?
        true
      else
        log_block(task_name) { instance_eval &task_block }
      end
    end

    def unsupported_scheme uri
      log_error "Babushka can't handle #{uri.scheme}:// URLs yet. But it can if you write a patch! :)"
    end

  end
end
