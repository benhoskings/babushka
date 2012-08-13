module Babushka

  class DefaultUnavailable < RuntimeError
    def initialize message
      super %{Not prompting for "#{message}" because we're running with '--defaults'.}
    end
  end

  class PromptUnavailable < RuntimeError
    def initialize message
      super %{Can't prompt for "#{message}" because STDIN isn't a terminal.}
    end
  end

  class Prompt
    extend LogHelpers

    module Helpers
      def confirm message, opts = {}, &block
        Prompt.confirm message, opts, &block
      end
    end

  class << self
    def suggest_value_for typo, choices
      if (possible_matches = choices.similar_to(typo.to_s)).empty?
        nil # nothing to suggest
      elsif possible_matches.length == 1
        confirm "#{"Did you mean".colorize('grey')} '#{possible_matches.first}'#{"?".colorize('grey')}" do
          possible_matches.first
        end or false
      else
        log "Similar: #{possible_matches.map {|d| "'#{d}'" }.join(', ')}"
        get_value("Did you mean any of those".colorize('grey'), :default => possible_matches.first)
      end
    end

    def confirm message, opts = {}, &block
      prompter = (!opts[:always_ask] && respond_to?(:var)) ? :var : :get_value
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

    def get_ip message, opts = {}
      get_value(message, opts.merge(
        :retry => "That's not an IP, like '10.0.1.1'."
      )) {|value|
        IP.new(value).valid?
      }
    end

    def get_ip_range message, opts = {}
      get_value(message, opts.merge(
        :retry => "That's not an IP range, like '10.0.1.x'."
      )) {|value|
        IPRange.new(value).valid?
      }
    end

    def get_path message, opts = {}
      get_value(message, opts.merge(
        :retry => "Doesn't exist, or not a directory."
      )) {|value|
        (value || '').p.dir?
      }
    end

    def get_value message, opts = {}, &block
      if opts[:choices] && opts[:choice_descriptions]
        raise ArgumentError, "You can't use the :choices and :choice_descriptions options together."
      elsif opts[:choice_descriptions]
        opts[:choices] = opts[:choice_descriptions].keys
      end
      if opts[:choices] && opts[:choices].any? {|c| !c.is_a?(String) }
        raise ArgumentError, "Choices must be passed as strings."
      end
      opts.defaults! :prompt => '? '
      prompt_and_read_value prompt_message(message, opts), opts.merge(:ask => !Base.task.opt(:defaults)), &block
    end


    private

    def prompt_message message, opts
      if opts[:choices] && opts[:choice_descriptions].nil?
        "#{message.chomp '?'} (#{opts[:choices] * ','})"
      else
        message.chomp '?'
      end + "#{" #{opts[:dynamic] ? '{' : '['}#{opts[:default]}#{opts[:dynamic] ? '}' : ']'}" if opts[:default]}"
    end

    def log_choice_descriptions descriptions
      unless descriptions.nil?
        max_length = descriptions.keys.map(&:length).max
        log "There are #{descriptions.length} choices:"
        descriptions.each_pair {|choice,description|
          log "#{choice.ljust(max_length)} - #{description}"
        }
      end
    end

    def prompt_and_read_value message, opts, &block
      if !opts[:default] && !opts[:ask]
        raise DefaultUnavailable.new(message)
      elsif opts[:ask] && !$stdin.tty?
        raise PromptUnavailable.new(message)
      else
        log_choice_descriptions opts[:choice_descriptions]
        log message, :newline => false

        if opts[:default] && !opts[:ask]
          puts '.'
          opts[:default]
        else
          read_value_from_prompt message, opts, &block
        end
      end
    end

    def read_value_from_prompt message, opts, &block
      value = nil

      value = read_from_prompt(opts[:prompt].end_with(' '), opts[:choices]).try(:chomp)
      value = opts[:default].to_s if value.blank? && !(opts[:default] && opts[:default].to_s.empty?)

      error = if opts[:choices] && !opts[:choices].include?(value)
        "That's not a valid choice"
      elsif block_given? && !yield(value)
        opts[:retry] || "That wasn't valid"
      elsif value.blank? && !(opts[:default] && opts[:default].empty?)
        "That was blank"
      elsif !opts[:confirmation] && %w[y yes].include?(value) && !confirm("Wait, do you mean the literal value '#{value}'?", :default => 'n', :always_ask => true)
        "Thought so :) Hit enter for the [default]"
      end

      if error
        log "#{error.end_with('.')} #{message}", :newline => false
        read_value_from_prompt message, opts, &block
      else
        value
      end
    end

    begin
      require 'readline'
      def read_from_prompt prompt, choices = nil
        using_libedit = !Readline.respond_to?(:vi_editing_mode)
        Readline.completion_append_character = nil

        Readline.completion_proc = if !choices.nil?
          L{|str| choices.select {|i| i.starts_with? choice } }
        else
          L{|str|
            Dir["#{str}*"].map {|path|
              path.end_with(if File.directory?(path)
                using_libedit ? '' : '/' # libedit adds its own trailing slash to dirs
              else
                ' ' # Add a trailing space to files
              end)
            }
          }
        end

        # This is required in addition to the call in bin/babushka.rb for
        # interrupts to work during Readline calls.
        Base.exit_on_interrupt!

        Readline.readline(prompt, true).try(:strip)
      end
    rescue LoadError
      def read_from_prompt prompt, choices = nil
        print prompt
        $stdin.gets.try(:strip)
      end
    end
  end
  end
end
