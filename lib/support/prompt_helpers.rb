module Babushka
  module PromptHelpers
    def prompt_for_path message, opts = {}
      prompt_for_value(message, opts.merge(
        :retry => "Doesn't exist, or not a directory."
      )) {|value|
        File.directory? value || ''
      }
    end

    def prompt_for_value message, in_opts = {}
      opts = {
        :prompt => '? '
      }.merge in_opts

      message = "#{message}#{" #{opts[:dynamic] ? '{' : '['}#{opts[:default]}#{opts[:dynamic] ? '}' : ']'}" if opts[:default]}"
      log message, :newline => false

      if Base.task.defaults? && opts[:default]
        puts '.'
        opts[:default]
      else
        read_value_from_prompt message, opts
      end
    end

    def read_value_from_prompt message, opts
      value = nil
      loop do
        value = read_from_prompt(opts[:prompt].end_with(' ')).chomp
        if block_given?
          break if yield value
        else
          value = opts[:default] if value.blank? && !(opts[:default] && opts[:default].empty?)
          break unless value.blank? && !(opts[:default] && opts[:default].empty?)
        end
        log "#{opts[:retry] || 'That was blank.'} #{message}", :newline => false
      end
      value
    end

    def read_from_prompt prompt
      require 'readline'
      Readline.readline prompt, true
    rescue LoadError => e
      print prompt
      $stdin.gets
    end
  end
end
