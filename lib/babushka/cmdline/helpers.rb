# coding: utf-8

module Babushka
  class Cmdline
    class Helpers
      extend LogHelpers

      def self.print_version opts = {}
        if opts[:full]
          log "Babushka v#{VERSION} (#{Base.ref}), (c) Ben Hoskings <ben@hoskings.net>"
        elsif Base.ref
          log "#{VERSION} (#{Base.ref})"
        else
          log "#{VERSION}"
        end
      end

      def self.print_usage
        log "\nThe gist:"
        log "  #{Base.program_name} <command> [options]"
        log "\nAlso:"
        log "  #{Base.program_name} help <command>  # Print command-specific usage info"
        log "  #{Base.program_name} <dep name>      # A shortcut for 'babushka meet <dep name>'"
        log "  #{Base.program_name} babushka        # Update babushka itself (what babushka.me/up does)"
      end

      def self.print_handlers
        log "\nCommands:"
        Handler.all.each {|handler|
          log "  #{handler.name.ljust(10)} #{handler.description}"
        }
      end

      def self.print_examples
        log "\nExamples:"
        log "  # Inspect the 'system' dep (and all its sub-deps) without touching the system.".colorize('grey')
        log "  #{Base.program_name} system --dry-run"
        log "\n"
        log "  # Meet the 'fish' dep (i.e. install fish and all its dependencies).".colorize('grey')
        log "  #{Base.program_name} fish"
        log "\n"
        log "  # Meet the 'user setup' dep, printing lots of debugging (including realtime".colorize('grey')
        log "  # shell command output).".colorize('grey')
        log "  #{Base.program_name} 'user setup' --debug"
      end

      def self.print_notes
        log "\nCommands can be abbrev'ed, as long as they remain unique."
        log "  e.g. '#{Base.program_name} l' is short for '#{Base.program_name} list'."
      end

      def self.github_autosource_regex
        /^\w+\:\/\/github\.com\/(.*)\/babushka-deps(\.git)?/
      end

      def self.generate_list_for to_list, filter_str
        context = to_list == :deps ? Base.program_name : ':template =>'
        match_str = filter_str.try(:downcase)
        Base.sources.all_present.each {|source|
          source.load!
        }.map {|source|
          [source, source.send(to_list).items]
        }.map {|(source,items)|
          if match_str.nil? || source.name.downcase[match_str]
            [source, items]
          else
            [source, items.select {|item| item.name.downcase[match_str] }]
          end
        }.select {|(_,items)|
          !items.empty?
        }.sort_by {|(source,_)|
          source.name
        }.each {|(source,items)|
          indent = (items.map {|item| "#{source.name}:#{item.name}".length }.max || 0) + 3
          log ""
          log "# #{source.name} (#{source.type})#{" - #{source.uri}" unless source.implicit?}"
          log "# #{items.length} #{to_list.to_s.chomp(items.length == 1 ? 's' : '')}#{" matching '#{filter_str}'" unless filter_str.nil?}:"
          items.each {|dep|
            log "#{context} #{"'#{source.name}:#{dep.name}'".ljust(indent)}"
          }
        }
      end
    end
  end
end
