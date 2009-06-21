require 'rubygems'
require 'open4'

require 'utils'

class Shell
  attr_reader :cmd, :result, :stdout, :stderr
  class ShellResult
    attr_reader :shell

    def initialize shell, opts, &block
      @shell, @opts, @block = shell, opts, block
    end

    def ok?; shell.ok? end

    def render
      unless ok? || @opts[:fail_ok]
        log_extra "$ #{shell.cmd}" unless Cfg[:debug]
        log_verbose shell.stderr.split("\n", 3)[0..1].join(', '), :as => :error
      end

      if @block.nil?
        shell.stdout if shell.ok?
      else
        @block.call shell
      end
    end
  end

  def initialize cmd
    @cmd = cmd
  end

  def ok?; result end

  def run opts = {}, &block
    debug "$ #{@cmd}".colorize('grey')
    @stdout, @stderr = nil, nil

    @result = Open4.popen4 @cmd do |pid,stdin,stdout,stderr|
      @stdout, @stderr = stdout.read.chomp, stderr.read.chomp
    end.exitstatus.zero?

    ShellResult.new(self, opts, &block).render
  end
end

def shell cmd, opts = {}, &block
  Shell.new(cmd).run opts, &block
end

def failable_shell cmd
  shell = nil
  Shell.new(cmd).run :fail_ok => true do |s|
    shell = s
  end
  shell
end

def which cmd_name, &block
  shell "which #{cmd_name}", &block
end

def in_dir dir, &block
  if dir.nil?
    yield
  else
    Dir.chdir dir do |path|
      log_verbose "in dir #{path} (#{Pathname(path).realpath})" do
        yield
      end
    end
  end
end

def cmd_dir cmd_name
  which("#{cmd_name}") {|shell|
    File.dirname shell.stdout if shell.ok?
  }
end

def sudo cmd, opts = {}, &block
  shell "sudo su - #{opts[:as] || 'root'} -c \"#{cmd.gsub('"', '\"')}\"", &block
end

def rake cmd, &block
  sudo "rake #{cmd} RAILS_ENV=#{rails_env}", :as => app_name, &block
end

def check_file file_name, method_name
  returning File.send method_name, file_name do |result|
    log_error "#{file_name} failed #{method_name.to_s.sub(/[?!]$/, '')} check." unless result
  end
end

def change_with_sed keyword, from, to, file
  sed = linux? ? 'sed' : 'gsed'
  if check_file file, :writable?
    # Remove the incorrect setting if it's there
    shell("#{sed} -ri 's/^#{keyword}\s+#{from}//' #{file}")
    # Add the correct setting unless it's already there
    shell("echo '#{keyword} #{to}' >> #{file}") if failable_shell("grep '^#{keyword}\s+#{to}' #{file}").stdout.empty?
  end
end

def append_to_file text, file
  if failable_shell("grep '^#{text}' #{file}").stdout.empty?
    shell %Q{echo "#{text.gsub('"', '\"')}" >> #{file}}.tap{|obj| log obj.inspect }
  end
end
