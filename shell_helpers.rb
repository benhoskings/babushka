require 'rubygems'
require 'open4'

require 'utils'

class Shell
  class ShellResult
    attr_reader :stdout, :stderr
    alias_method :to_s, :stdout
    alias_method :output, :stdout
    alias_method :error, :stderr

    def initialize result, stdout, stderr, &block
      @result, @stdout, @stderr, @block = result, stdout, stderr, block
    end

    def ok?
      @result
    end

    def render
      if @block.nil?
        output if ok?
      else
        @block.call ok?, stdout, stderr
      end
    end
  end

  def initialize cmd
    @cmd = cmd
  end

  def run &block
    debug "$ #{@cmd}".colorize('grey')
    _stdout, _stderr = nil, nil
    status = Open4.popen4 @cmd do |pid,stdin,stdout,stderr|
      _stdout, _stderr = stdout.read, stderr.read
    end
    returning ShellResult.new(status.exitstatus == 0, _stdout.chomp, _stderr, &block).render do |result|
      debug "`#{@cmd}` failed with '#{_stderr.chomp}'", :error => true unless result
    end
  end
end

def shell cmd, &block
  Shell.new(cmd).run &block
end

def which cmd_name, &block
  shell "which #{cmd_name}", &block
end

def cmd_dir cmd_name
  which("#{cmd_name}") {|result, output, error|
    File.dirname output if result
  }
end

def sudo cmd, &block
  shell "sudo #{cmd}", &block
end

def rake cmd, &block
  shell "rake #{cmd} RAILS_ENV=#{RAILS_ENV}", &block
end
