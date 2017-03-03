module Babushka
  class SourcePool

    include LogHelpers

    SEPARATOR = ':'

    attr_reader :source_opts

    def initialize source_opts = {}
      @source_opts = source_opts
    end

    def default
      [
        anonymous, # deps defined at the console, or otherwise not in a source
        core, # the deps bundled with babushka, for self-install
        current_dir, # the deps found in ./babushka-deps when babushka is run
        personal # the deps found in ~/.babushka/deps when babushka is run
      ].freeze
    end

    def default_names
      default.map {|source| source.deps.names }.flatten.uniq
    end

    def all_present
      default.dup.concat(Source.present)
    end

    def anonymous
      @anonymous ||= ImplicitSource.new('anonymous')
    end

    def core
      @core ||= Source.new(Path.path / 'deps', 'core')
    end

    def current_dir
      @current_dir ||= Source.new('./babushka-deps', 'current dir')
    end

    def personal
      @personal ||= Source.new('~/.babushka/deps', 'personal')
    end

    def source_for name
      (
        all_present.detect {|source| source.name == name } ||
        Source.for_remote(name)
      ).tap {|source|
        source.load!(source_opts[:update])
      }
    end

    # Look up the dep specified by +dep_name+, yielding it to the block if it
    # was found.
    #
    # If no such dep exists, suggest similarly spelt deps to the user.
    def find_or_suggest dep_name, opts = {}, &block
      if (dep = dep_for(dep_name, opts)).nil?
        log_stderr "#{dep_name.to_s.colorize 'grey'} #{"<- this dep isn't defined!".colorize('red')}"
        suggestions = Babushka::Spell.for(dep_name.to_s, choices: default_names)
        log "Perhaps you meant #{suggestions.map {|s| "'#{s}'" }.to_list(:conj => 'or')}?".colorize('grey') if suggestions.any?
      elsif block.nil?
        dep
      else
        block.call(dep)
      end
    end

    def dep_for dep_spec, opts = {}
      raise ArgumentError, "The dep spec #{dep_spec.inspect} isn't a String or Dep." unless [String, Dep].include?(dep_spec.class)

      if dep_spec.is_a?(Dep)
        dep_spec
      elsif dep_spec[SEPARATOR] # If a source was specified, that's where we load from.
        source_name, dep_name = dep_spec.split(SEPARATOR, 2)
        source_for(source_name).find(dep_name)
      elsif opts[:from] # Next, try opts[:from], the requiring dep's source.
        opts[:from].find(dep_spec) || dep_for(dep_spec)
      else # Otherwise, try the standard set.
        matches = default.map {|source| source.find(dep_spec) }.flatten.compact
        log_warn "Multiple sources (#{matches.map(&:dep_source).map(&:name).join(',')}) define '#{dep_spec}'; choosing '#{matches.first.full_name}'." if matches.length > 1
        matches.first
      end
    end

    def template_for template_spec, opts = {}
      if template_spec.nil?
        nil
      elsif template_spec[/#{SEPARATOR}/] # If a source was specified, that's where we load from.
        source_name, template_name = template_spec.split(SEPARATOR, 2)
        source_for(source_name).find_template(template_name)
      elsif opts[:from]
        opts[:from].find_template(template_spec) || template_for(template_spec)
      else
        matches = default.map {|source| source.find_template(template_spec) }.flatten.compact
        if matches.length > 1
          log "Multiple sources (#{matches.map(&:source).map(&:name).join(',')}) contain a template called '#{template_spec}'."
        else
          matches.first
        end
      end
    end

    def update!
      all_present.select {|source|
        source.remote?
      }.tap {|sources|
        log "Updating #{sources.length} source#{'s' unless sources.length == 1}."
      }.map {|source|
        source.update!
      }.all?
    end

    def list!
      Logging.log_table(
        ['Name', 'Source path', 'Type', 'Last updated'],
        Source.present.tap {|sources|
          log "There #{sources.length == 1 ? 'is' : 'are'} #{sources.length} source#{'s' unless sources.length == 1} in #{Source.source_prefix}:"
          log ''
        }.map(&:description_pieces)
      )
    end

    def local_only?
      @local_only
    end

    def local_only &block
      previously = @local_only
      @local_only = true
      yield
    ensure
      @local_only = previously
    end

    def load_context context, &block
      (@load_contexts ||= []).push context
      yield
    ensure
      @load_contexts.pop
    end

    def current_real_load_source
      current_load_context[:source]
    end

    def current_load_source
      current_real_load_source || anonymous
    end

    def current_load_path
      path = current_load_context[:path]
      path.p unless path.nil?
    end

    def current_load_opts
      current_load_context[:opts] || {}
    end

    private

    def current_load_context
      (@load_contexts ||= []).last || {}
    end

  end
end
