module Babushka
  class BaseDepRunner < DepRunner
    include GitHelpers

    delegate :pkg_manager, :to => :definer

    private

    def version
      var(:versions)[name]
    end

    def set_version version_str
      merge :versions, name => version_str
    end

    def provided? provided_list = provides, custom_cmd_dir = nil
      apps, commands = provided_list.partition {|i| i.to_s[/\.app\/?$/] }
      apps_in_path?(apps) and cmds_in_path?(commands)
    end

    def apps_in_path? apps
      present, missing = [*apps].partition {|app_name| app_dir(app_name) }

      returning missing.empty? do |result|
        if result
          log "#{present.map {|i| "'#{i}'" }.to_list} #{present.length == 1 ? 'is' : 'are'} present." unless present.empty?
        else
          log "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing."
        end
      end
    end

    def cmds_in_path? commands
      dir_hash = [*commands].group_by {|cmd_name| cmd_dir(cmd_name) }

      if dir_hash.keys.compact.length > 1
        log_error "The commands for '#{name}' run from more than one place."
        log dir_hash.values.map {|cmds| cmd_location_str_for cmds }.to_list(:oxford => true, :conj => 'but').end_with('.')
        :fail
      else
        cmds = dir_hash.values.first
        returning dir_hash[nil].blank? do |result|
          if result
            log cmd_location_str_for(cmds).end_with('.') unless cmds.empty?
          else
            log "#{dir_hash[nil].map {|i| "'#{i}'" }.to_list} #{dir_hash[nil].length == 1 ? 'is' : 'are'} missing."
          end
        end
      end
    end

    def app_dir app_name
      %w[/Applications ~/Applications].detect {|app_path|
        (app_path / app_name).glob.select {|entry|
          (entry / 'Contents/MacOS').exists?
        }.any?
      }
    end

    def cmd_location_str_for cmds
      "#{cmds.map {|i| "'#{i}'" }.to_list(:conj => '&')} run#{'s' if cmds.length == 1} from #{cmd_dir(cmds.first)}"
    end

    private

    def setup_source_uris
      parse_uris
      definer.requires_when_unmet(@uris.map(&:scheme).uniq & %w[ git ])
    end

    def parse_uris
      @uris = source.map(&uri_processor(:escape)).map(&uri_processor(:parse))
      @extra_uris = extra_source.map(&uri_processor(:escape)).map(&uri_processor(:parse))
    end

    def uri_processor(method_name)
      L{|uri| URI.send(method_name, uri.respond_to?(:call) ? uri.call : uri.to_s) }
    end

    def process_sources &block
      @extra_uris.each {|uri| handle_source uri } unless @extra_uris.nil?
      @uris.all? {|uri| handle_source uri, &block } unless @uris.nil?
    end


    # single-URI methods

    def handle_source uri, &block
      uri = uri_processor(:parse).call(uri) unless uri.is_a?(URI)
      ({
        'http' => L{ Archive.get_source(uri, &block) },
        'ftp' => L{ Archive.get_source(uri, &block) },
        'git' => L{ git(uri, &block) }
      }[uri.scheme] || L{ unsupported_scheme(uri) }).call
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
