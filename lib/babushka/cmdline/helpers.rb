# coding: utf-8

module Babushka
  module Cmdline
    module Helpers
      module_function

      def search_results_for q
        YAML.load(search_webservice_for(q).body).sort_by {|i|
          -i[:runs_this_week]
        }.map {|i|
          [
            i[:name],
            i[:source_uri],
            ((i[:runs_this_week] && i[:runs_this_week] > 0) ? "#{i[:runs_this_week]} this week" : "#{i[:total_runs]} ever"),
            ((i[:runs_this_week] && i[:runs_this_week] > 0) ? "#{(i[:success_rate_this_week] * 100).round}%" : ((i[:total_runs] && i[:total_runs] > 0) ? "#{(i[:total_success_rate] * 100).round}%" : '')),
            (i[:source_uri][github_autosource_regex] ? "#{Base.program_name} #{$1}:#{"'" if i[:name][/\s/]}#{i[:name]}#{"'" if i[:name][/\s/]}" : '✣')
          ]
        }
      end

      def github_autosource_regex
        /^git\:\/\/github\.com\/(.*)\/babushka-deps(\.git)?/
      end

      def search_webservice_for q
        Net::HTTP.start('babushka.me') {|http|
          http.get URI.encode("/deps/search.yaml/#{q}")
        }
      end

      def generate_list_for to_list, filter_str
        context = to_list == :deps ? Base.program_name : ':template =>'
        Base.sources.all_present.each {|source|
          source.load!
        }.map {|source|
          [source, source.send(to_list).send(to_list)]
        }.map {|(source,items)|
          if filter_str.nil? || source.name[filter_str]
            [source, items]
          else
            [source, items.select {|item| item.name[filter_str] }]
          end
        }.select {|(source,items)|
          !items.empty?
        }.sort_by {|(source,items)|
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
