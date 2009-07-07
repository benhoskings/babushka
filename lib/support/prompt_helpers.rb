module Babushka
  module PromptHelpers
    def read_path_from_prompt message, opts = {}
      read_value_from_prompt(message, opts.merge(
        :retry => "Doesn't exist, or not a directory."
      )) {|value|
        File.directory? value || ''
      }
    end

    def read_value_from_prompt message, in_opts = {}
      opts = {
        :prompt => '? '
      }.merge in_opts

      value = nil
      message = "#{message}#{" [#{opts[:default]}]" if opts[:default]}"
      log message, :newline => false
      loop do
        value = read_from_prompt opts[:prompt].end_with(' ')
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
