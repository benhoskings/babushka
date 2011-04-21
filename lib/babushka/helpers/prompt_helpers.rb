module Babushka
  module PromptHelpers
    def confirm message, opts = {}, &block
      prompter = (!opts[:always_ask] && respond_to?(:var)) ? :var : :prompt_for_value
      answer = send(prompter, message,
        :message => message,
        :confirmation => true,
        :default => (opts[:default] || 'y')
      ).starts_with?('y')

      if block.nil?
        answer
      elsif answer
        block.call
      elsif opts[:otherwise]
        log opts[:otherwise]
      end
    end

    def prompt_for_ip message, opts = {}
      prompt_for_value(message, opts.merge(
        :retry => "That's not an IP, like '10.0.1.1'."
      )) {|value|
        IP.new(value).valid?
      }
    end

    def prompt_for_ip_range message, opts = {}
      prompt_for_value(message, opts.merge(
        :retry => "That's not an IP range, like '10.0.1.x'."
      )) {|value|
        IPRange.new(value).valid?
      }
    end

    def prompt_for_path message, opts = {}
      prompt_for_value(message, opts.merge(
        :retry => "Doesn't exist, or not a directory."
      )) {|value|
        (value || '').p.dir?
      }
    end

    def prompt_for_value message, opts = {}, &block
      opts.defaults! :prompt => '? '
      prompt_and_read_value prompt_message(message, opts), opts, &block
    end


    private

    def prompt_message message, opts
      if opts[:choices] && opts[:choice_descriptions].blank?
        "#{message.chomp '?'} (#{opts[:choices] * ','})"
      else
        message.chomp '?'
      end + "#{" #{opts[:dynamic] ? '{' : '['}#{opts[:default]}#{opts[:dynamic] ? '}' : ']'}" if opts[:default]}"
    end

    def log_choice_descriptions descriptions
      unless descriptions.blank?
        max_length = descriptions.keys.map(&:length).max
        log "There are #{descriptions.length} choices:"
        descriptions.each_pair {|choice,description|
          log "#{choice.ljust(max_length)} - #{description}"
        }
      end
    end

    def prompt_and_read_value message, opts, &block
      log_choice_descriptions opts[:choice_descriptions]

      log message, :newline => false

      if Base.task.opt(:defaults) && opts[:default]
        puts '.'
        opts[:default]
      else
        read_value_from_prompt message, opts, &block
      end
    end

    def read_value_from_prompt message, opts, &block
      value = nil
      10.times do
        value = read_from_prompt(opts[:prompt].end_with(' '), opts[:choices]).chomp
        value = opts[:default] if value.blank? && !(opts[:default] && opts[:default].to_s.empty?)

        error_message = if opts[:choices] && !value.in?(opts[:choices])
          "That's not a valid choice"
        elsif block_given? && !yield(value)
          opts[:retry]
        elsif value.blank? && !(opts[:default] && opts[:default].empty?)
          "That was blank"
        elsif !opts[:confirmation] && value == 'y' && !confirm("Wait, do you mean the literal value 'y'?", :default => 'n', :always_ask => true)
          "Thought so :) Hit enter for the [default]"
        else
          break # success
          nil
        end

        value = nil
        log "#{error_message.end_with('.')} #{message}", :newline => false
      end
      value
    end

    def read_from_prompt prompt, choices = nil
      require 'readline'

      if choices.nil?
        Readline.completion_proc = L{|str| Dir["#{str}*"] }
      else
        Readline.completion_proc = L{|choice| choices.select {|i| i.starts_with? choice } }
      end

      # This is required in addition to the call in bin/babushka.rb for
      # interrupts to work during Readline calls.
      Base.exit_on_interrupt!

      Readline.readline(prompt, true).strip
    rescue LoadError => e
      print prompt
      $stdin.gets.strip
    end
  end
end
