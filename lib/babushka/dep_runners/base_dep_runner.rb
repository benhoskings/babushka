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
            log cmd_location_str_for(ours.empty? ? other : ours).end_with('.')
          else
            log "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing."
          end
        end
      end
    end

    def cmd_location_str_for cmds
      "#{cmds.map {|i| "'#{i}'" }.to_list} run#{'s' if cmds.length == 1} from #{cmd_dir(cmds.first)}"
    end

    def dmg url, &block
      download url
      output = shell "hdiutil attach #{File.basename url}"
      unless output.nil?
        path = output.val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/)
        returning yield path do
          shell "hdiutil detach #{path}"
        end
      end
    end

    def source url, filename = nil, &block
      in_build_dir {
        output = get_source url, filename
        unless output.nil?
          in_build_dir output do |path|
            yield path
          end
        end
      }
    end

  end
end
