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
        :prompt => '? ',
        :persist => true
      }.merge in_opts

      value = nil
      log message, :newline => false
      loop do
        value = Readline.readline opts[:prompt].end_with(' ')
        break unless (block_given? ? !yield(value) : value.blank?) && opts[:persist]
        log "#{opts[:retry] || 'That was blank.'} #{message}", :newline => false
      end
      value
    end
  end
end
