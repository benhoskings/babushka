require 'readline'

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
        value = Readline.readline opts[:prompt].end_with(' '), true
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
  end
end
