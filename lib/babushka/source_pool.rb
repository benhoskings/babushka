module Babushka
  class SourcePool

    include LogHelpers

    SEPARATOR = ':'

    def current
      @current ||= default.concat(standard)
      @current.dup
    end

    def default
      [anonymous, core].dup
    end

    def current_names
      current.map {|source| source.deps.names }.flatten.uniq
    end

    def all_present
      current.concat(Source.present)
    end

    def anonymous
      @anonymous ||= Source.new(nil, :name => 'anonymous')
    end

    def core
      @core ||= Source.new(Path.path / 'deps', :name => 'core')
    end

    def current_dir
      @current_dir ||= Source.new('./babushka-deps', :name => 'current dir')
    end

    def personal
      @personal ||= Source.new('~/.babushka/deps', :name => 'personal')
    end

    def standard
      [current_dir, personal]
    end

    def source_for name
      (
        all_present.detect {|source| source.name == name } ||
        Source.for_remote(name)
      ).tap {|source|
        source.load!(Base.task.opt(:update))
      }
    end

    def dep_for dep_spec, opts = {}
      if dep_spec.is_a?(Dep)
        dep_spec
      elsif dep_spec[/#{SEPARATOR}/] # If a source was specified, that's where we load from.
        source_name, dep_name = dep_spec.split(SEPARATOR, 2)
        source_for(source_name).find(dep_name)
      elsif opts[:from] # Next, try opts[:from], the requiring dep's source.
        opts[:from].find(dep_spec) || dep_for(dep_spec)
      else # Otherwise, try the standard set.
        matches = current.map {|source| source.find(dep_spec) }.flatten.compact
        if matches.length > 1
          log "Multiple sources (#{matches.map(&:dep_source).map(&:name).join(',')}) contain a dep called '#{dep_spec}'."
        else
          matches.first
        end
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
          log "Multiple sources (#{matches.map(&:source).map(&:name).join(',')}) contain a template called '#{template_name}'."
        else
          matches.first
        end
      end
    end

    def update!
      all_present.select {|source|
        source.cloneable?
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
      current_load_context[:path].try(:p)
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
