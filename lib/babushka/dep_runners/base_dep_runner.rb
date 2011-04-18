module Babushka
  module BaseDepRunner
    include GitHelpers
    include PromptHelpers
    include UriHelpers

    private

    # TODO: remove these two once the new version handling is done.
    def version
      var(:versions)[name]
    end

    def set_version version_str
      merge :versions, name => version_str
    end

    # deprecated
    def provided? provided_list = provides
      log_error "#{caller.first}: #provided? has been renamed to #in_path?."
      in_path? provided_list
    end

    # TODO: solve cmd/app and string/version handling better.
    def in_path? provided_list = provides
      apps, command_names = [*provided_list].partition {|i| i.to_s[/\.app\/?$/] }
      commands = command_names.versions
      apps_in_path?(apps) and cmds_in_path?(commands) and matching_versions?(commands)
    end

    def apps_in_path? apps
      present, missing = [*apps].partition {|app_name| app_dir(app_name) }

      missing.empty?.tap {|result|
        if result
          log "#{present.map {|i| "'#{i}'" }.to_list} #{present.length == 1 ? 'is' : 'are'} present." unless present.empty?
        else
          log "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing."
        end
      }
    end

    def cmds_in_path? commands
      dir_hash = [*commands].group_by {|cmd| cmd_dir(cmd.name) }

      if dir_hash.keys.compact.length > 1
        unmeetable "The commands for '#{name}' run from more than one place.\n" +
          dir_hash.values.map {|cmds|
            cmd_location_str_for cmds
          }.to_list(:oxford => true, :conj => 'but').end_with('.')
      else
        cmds = dir_hash.values.first
        dir_hash[nil].blank?.tap {|result|
          if result
            log cmd_location_str_for(cmds).end_with('.') unless cmds.blank?
          else
            log "#{dir_hash[nil].map {|i| "'#{i}'" }.to_list} #{dir_hash[nil].length == 1 ? 'is' : 'are'} missing."
          end
        }
      end
    end

    def matching_versions? commands
      versions = commands.select {|cmd|
        !cmd.version.nil?
      }.inject({}) {|hsh,cmd|
        hsh[cmd] = shell("#{cmd.name} --version").split(/[\s\-]/).detect {|piece|
          begin
            cmd.matches? piece.to_version
          rescue VersionStrError
            false
          end
        }
        log "#{cmd.name} is #{hsh[cmd]}, which is#{"n't" unless hsh[cmd]} #{cmd.version}.", :as => (:ok if hsh[cmd])
        hsh
      }
      versions.values.all?
    end

    def app_dir app_name
      prefix.find {|app_path|
        (app_path.to_s / app_name).glob.select {|entry|
          (entry / 'Contents/MacOS').exists?
        }.first
      }
    end

    def cmd_location_str_for cmds
      "#{cmds.map {|i| "'#{i.name}'" }.to_list(:conj => '&')} run#{'s' if cmds.length == 1} from #{cmd_dir(cmds.first.name)}"
    end

    def call_task task_name
      if (task_block = send(task_name)).nil?
        true
      else
        instance_eval &task_block
      end
    end

  end
end
