module Babushka
  class PathChecker
    extend ShellHelpers

    # TODO: solve cmd/app and string/version handling better.
    def self.in_path? provided_list
      apps, command_names = [*provided_list].partition {|i| i.to_s[/\.app\/?$/] }
      commands = command_names.versions
      apps_in_path?(apps) and cmds_in_path?(commands) and matching_versions?(commands)
    end

    private

    def self.apps_in_path? apps
      present, missing = [*apps].partition {|app_name| app_dir(app_name) }

      missing.empty?.tap {|result|
        if result
          log "#{present.map {|i| "'#{i}'" }.to_list} #{present.length == 1 ? 'is' : 'are'} present." unless present.empty?
        else
          log "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'}n't present anywhere in $PATH."
        end
      }
    end

    def self.cmds_in_path? commands
      dir_hash = [*commands].group_by {|cmd| cmd_dir(cmd.name) }

      if dir_hash.keys.compact.length > 1
        log_error "The commands for '#{name}' run from more than one place.\n" +
          dir_hash.values.map {|cmds|
            cmd_location_str_for cmds
          }.to_list(:oxford => true, :conj => 'but').end_with('.')
        unmeetable unless confirm("Multiple installations might indicate a problem. Meet anyway?", :default => 'n')
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

    def self.matching_versions? commands
      versions = commands.select {|cmd|
        !cmd.version.nil?
      }.inject({}) {|hsh,cmd|
        possible_versions = (shell("#{cmd.name} --version") || '').split(/[\s\-]/).map {|piece|
          begin
            piece.to_version
          rescue VersionStrError
            nil
          end
        }.compact
        hsh[cmd] = possible_versions.detect {|piece| cmd.matches?(piece) }
        if hsh[cmd] == cmd.version
          log_ok "#{cmd.name} is #{cmd.version}."
        else
          log "#{cmd.name} is #{hsh[cmd] || possible_versions.first}, which is#{"n't" unless hsh[cmd]} #{cmd.version}.", :as => (:ok if hsh[cmd])
        end
        hsh
      }
      versions.values.all?
    end

    def self.app_dir app_name
      prefix.find {|app_path|
        (app_path.to_s / app_name).glob.select {|entry|
          (entry / 'Contents/MacOS').exists?
        }.first
      }
    end

    def self.cmd_location_str_for cmds
      "#{cmds.map {|i| "'#{i.name}'" }.to_list(:conj => '&')} run#{'s' if cmds.length == 1} from #{cmd_dir(cmds.first.name)}"
    end
  end
end