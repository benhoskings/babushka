module Babushka
  module ShellHelpers
    def shell cmd, opts = {}, &block
      shell_method = opts.delete(:sudo) ? :sudo : :shell_cmd
      send shell_method, cmd, opts, &block
    end

    def failable_shell cmd, opts = {}
      shell = nil
      Babushka::Shell.new(cmd).run opts.merge(:fail_ok => true) do |s|
        shell = s
      end
      shell
    end

    def sudo cmd, opts = {}, &block
      cmd = cmd.to_s
      sudo_cmd = if opts[:su] || cmd[' |'] || cmd[' >']
        "sudo su - #{opts[:as] || 'root'} -c \"#{cmd.gsub('"', '\"')}\""
      else
        "sudo -u #{opts[:as] || 'root'} #{cmd}"
      end
      shell sudo_cmd, opts, &block
    end

    def which cmd_name, &block
      result = shell "which #{cmd_name}", &block
      result unless result.nil? || result["no #{cmd_name} in"]
    end

    def cmd_dir cmd_name
      which("#{cmd_name}") {|shell|
        File.dirname shell.stdout if shell.ok?
      }
    end

    def log_block message, opts = {}, &block
      log "#{message}...", :newline => false
      returning block.call do |result|
        log result ? ' done.' : ' failed', :as => (result ? nil : :error), :indentation => false
      end
    end

    def log_shell message, cmd, opts = {}, &block
      log_block message do
        opts.delete(:sudo) ? sudo(cmd, opts.merge(:spinner => true), &block) : shell(cmd, opts.merge(:spinner => true), &block)
      end
    end

    def log_shell_with_a_block_to_scan_stdout_for_apps_that_have_broken_return_values message, cmd, opts = {}, &block
      log_block message do
        send opts.delete(:sudo) ? :sudo : :shell, cmd, opts.merge(:failable => true), &block
      end
    end

    private

    def shell_cmd cmd, opts = {}, &block
      Shell.new(cmd).run opts, &block
    end
  end
end
