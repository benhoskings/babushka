require 'rubygems'
require 'open4'

module Babushka
  module ShellHelpers
    def self.included base # :nodoc:
      base.send :include, HelperMethods
    end

    module HelperMethods
      def shell cmd, opts = {}, &block
        Shell.new(cmd).run opts, &block
      end
    end
  end

  class Shell
    attr_reader :cmd, :result, :stdout, :stderr
    class ShellResult
      attr_reader :shell

      def initialize shell, opts, &block
        @shell, @opts, @block = shell, opts, block
      end

      def ok?; shell.ok? end

      def render
        log_verbose shell.stderr.split("\n", 3)[0..1].join(', '), :as => :error if Base.opts[:debug] unless ok? || @opts[:fail_ok]

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
        unless opts[:input].nil?
          stdin << opts[:input]
          stdin.close
        end
        @stdout, @stderr = stdout.read.chomp, stderr.read.chomp
      end.exitstatus.zero?

      ShellResult.new(self, opts, &block).render
    end
  end
end
