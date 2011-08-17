module Babushka
  class MetaDep
    include LogHelpers

    INVALID_NAMES = %w[base]

    VALID_NAME_START_CHARS = /[a-z]/
    VALID_NAME_CHARS = /#{VALID_NAME_START_CHARS}[a-z0-9_]*/
    VALID_NAME_START = /^#{VALID_NAME_START_CHARS}/
    VALID_NAME = /\A#{VALID_NAME_CHARS}\z/m

    TEMPLATE_NAME_MATCH = /\A.+\.(#{VALID_NAME_CHARS})\z/m

    def self.for supplied_name, source, opts, &block
      name = supplied_name.to_s.downcase

      if name.empty?
        raise ArgumentError, "You can't define a template with a blank name."
      elsif INVALID_NAMES.include? name
        raise ArgumentError, "You can't use '#{name}' for a template name, because it's reserved."
      elsif name[VALID_NAME_START].nil?
        raise ArgumentError, "You can't use '#{name}' for a template name - it must start with a letter."
      elsif name[VALID_NAME].nil?
        raise ArgumentError, "You can't use '#{name}' for a template name - it can only contain [a-z0-9_]."
      elsif Base.sources.current_load_source.templates.for(name)
        raise ArgumentError, "A template called '#{name}' has already been defined."
      else
        new name, source, opts, &block
      end
    end

    attr_reader :name, :source, :opts, :context_class

    def desc; context_class.desc end

    def initialize name, source, opts, &block
      @name, @source, @opts, @block = name, source, opts, block
      debug "Defining #{source.name}:#{name} template"
      @context_class = build_context block
      source.templates.register self
    end

    # Returns this template's name, including the source name as a prefix if
    # this template is in a cloneable source.
    #
    # A cloneable source is one that babushka knows how to automatically
    # update; i.e. a source that babushka could have installed itself.
    #
    # In effect, a cloneable source is one whose deps you prefix when you run
    # them, so this method returns the template's name in the same form as you
    # would refer to it when using it from another source.
    def contextual_name
      source.cloneable? ? "#{source.name}:#{name}" : name
    end

    def build_context block
      Class.new(MetaDepContext, &block).tap {|context|
        shadow = self
        context.metaclass.send :define_method, :source_template do
          shadow
        end
      }
    end
  end
end
