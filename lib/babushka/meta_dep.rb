module Babushka
  class MetaDep
    INVALID_NAMES = %w[base]

    VALID_NAME_START_CHARS = /[a-z]/
    VALID_NAME_CHARS = /#{VALID_NAME_START_CHARS}[a-z0-9_ ]*/
    VALID_SUFFIX_CHARS = /#{VALID_NAME_START_CHARS}[a-z0-9_]*/
    VALID_NAME_START = /^#{VALID_NAME_START_CHARS}/
    VALID_NAME = /\A#{VALID_NAME_CHARS}\z/m
    VALID_SUFFIX = /\A#{VALID_SUFFIX_CHARS}\z/m

    TEMPLATE_SUFFIX = /\A.+\.(#{VALID_SUFFIX_CHARS})\z/m

    def self.for supplied_name, source, opts, &block
      name = supplied_name.to_s.downcase
      if name.starts_with? '.'
        name = name[1..-1]
        opts.update :suffix => true
      end

      if name.to_s.blank?
        raise ArgumentError, "You can't define a template with a blank name."
      elsif name.in? INVALID_NAMES
        raise ArgumentError, "You can't use '#{name}' for a template name, because it's reserved."
      elsif name[VALID_NAME_START].nil?
        raise ArgumentError, "You can't use '#{name}' for a template name - it must start with a letter."
      elsif !opts[:suffix] && name[VALID_NAME].nil?
        raise ArgumentError, "You can't use '#{name}' for a template name - it can only contain [a-z0-9_]."
      elsif opts[:suffix] && name[VALID_SUFFIX].nil?
        raise ArgumentError, "You can't use '#{name}' for a suffixed template name - it can only contain [a-z0-9_]."
      elsif Base.sources.current_load_source.templates.for(name)
        raise ArgumentError, "A template called '#{name}' has already been defined."
      else
        new name, source, opts, &block
      end
    end

    attr_reader :name, :source, :opts, :context_class

    delegate :desc, :to => :context_class

    def initialize name, source, opts, &block
      @name, @source, @opts, @block = name, source, opts, block
      @context_class = build_context block
      source.templates.register self
    end

    def suffixed?
      opts[:suffix]
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
