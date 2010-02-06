module Babushka
  class BaseDepRunner < DepRunner
    include GitHelpers

    delegate :pkg_manager, :to => :definer

    private

    # This probably should be elsewhere, because it only works on DepRunners that
    # define #provides.
    def cmds_in_path? commands = provides, custom_cmd_dir = nil
      present, missing = [*commands].partition {|cmd_name| cmd_dir(cmd_name) }
      ours, other = if custom_cmd_dir
        present.partition {|cmd_name| cmd_dir(cmd_name) == custom_cmd_dir }
      else
        present.partition {|cmd_name| pkg_manager.cmd_in_path? cmd_name }
      end

      if !ours.empty? and !other.empty?
        log_error "The commands for #{name} run from more than one place."
        log "#{cmd_location_str_for ours}, but #{cmd_location_str_for other}."
        :fail
      else
        returning missing.empty? do |result|
          if result
            log cmd_location_str_for(ours.empty? ? other : ours).end_with('.') unless other.empty? && ours.empty?
          else
            log "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing."
          end
        end
      end
    end

    def cmd_location_str_for cmds
      "#{cmds.map {|i| "'#{i}'" }.to_list} run#{'s' if cmds.length == 1} from #{cmd_dir(cmds.first)}"
    end

    private

    def setup_source_uris
      parse_uris
      definer.requires(@uris.map(&:scheme).uniq & %w[ git ])
    end

    def parse_uris
      @uris = source.map &uri_parser
      @extra_uris = extra_source.map &uri_parser
    end

    def uri_parser
      L{|uri| URI.parse(uri.respond_to?(:call) ? uri.call : uri.to_s) }
    end

    def process_sources &block
      @extra_uris.each {|uri| handle_source uri }
      @uris.all? {|uri| handle_source uri, &block }
    end


    # single-URI methods

    def handle_source uri, &block
      uri = uri_parser.call(uri) unless uri.is_a?(URI)
      ({
        'http' => L{ Archive.get_source(uri, &block) },
        'ftp' => L{ Archive.get_source(uri, &block) },
        'git' => L{ git(uri, &block) }
      }[uri.scheme] || L{ unsupported_scheme(uri) }).call
    end

    def default_configure_command
      "#{configure_env.map(&:to_s).join} ./configure --prefix=#{prefix.first} #{configure_args.map(&:to_s).join(' ')}"
    end

    def call_task task_name, opts = {}
      if (task_block = send(task_name)).nil?
        true
      else
        instance_eval &task_block
      end
    end

    def unsupported_scheme uri
      log_error "Babushka can't handle #{uri.scheme}:// URLs yet. But it can if you write a patch! :)"
    end

  end
end
