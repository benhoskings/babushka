require 'rubygems'
require 'open4'

require 'utils'

class Shell
  attr_reader :cmd, :result, :stdout, :stderr
  class ShellResult
    attr_reader :shell

    def initialize shell, &block
      @shell, @block = shell, block
    end

    def ok?; shell.ok? end

    def render
      log_error "`#{shell.cmd}` failed with '#{shell.stderr.split("\n", 3)[0..1].join(', ')}'" unless ok?
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

  def run &block
    debug "$ #{@cmd}".colorize('grey')
    @stdout, @stderr = nil, nil

    @result = Open4.popen4 @cmd do |pid,stdin,stdout,stderr|
      @stdout, @stderr = stdout.read.chomp, stderr.read.chomp
    end.exitstatus.zero?

    ShellResult.new(self, &block).render
  end
end

def shell cmd, &block
  Shell.new(cmd).run &block
end

def which cmd_name, &block
  shell "which #{cmd_name}", &block
end

def in_dir dir, &block
  Dir.chdir dir do |path|
    debug "in dir #{path} (#{Pathname(path).realpath})" do
      yield
    end
  end
end

def cmd_dir cmd_name
  which("#{cmd_name}") {|shell|
    File.dirname shell.stdout if shell.ok?
  }
end

def sudo cmd, &block
  shell "sudo #{cmd}", &block
end

def rake cmd, &block
  shell "rake #{cmd} RAILS_ENV=#{RAILS_ENV}", &block
end
