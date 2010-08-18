module Babushka
  class BugReporter
    extend PromptHelpers

    def self.report dep_name
      confirm "I can file a bug report for that now, if you like.", :default => 'n', :otherwise => "OK, you're on your own :)" do
        post_report dep_name,
          (which('git') && shell('git config github.user')) || 'anonymous',
          read_file(Base.task.var_path_for(dep_name)),
          read_file(Base.task.log_path_for(dep_name))
      end
    end


    private

    # gist.github.com API example at http://gist.github.com/4277
    def self.post_report dep_name, user, vars, log
      require 'net/http'
      require 'uri'

      returning(Net::HTTP.post_form(
        URI.parse('http://gist.github.com/api/v1/xml/new'),
        {
          "files[from]" => user,
          "files[vars.yml]" => vars,
          "files[#{dep_name}.log]" => log.decolorize
        }
      )) do |response|
        report_report_result dep_name, response
      end.is_a? Net::HTTPSuccess
    end

    def self.report_report_result dep_name, response
      if response.is_a? Net::HTTPSuccess
        gist_id = response.body.scan(/<repo>(\d+)<\/repo>/).flatten.first
        if gist_id.blank?
          log "Done, but the report's URL couldn't be parsed. Here's some info:"
          log response.body
        else
          log "You can view the report at http://gist.github.com/#{gist_id} - thanks :)"
        end
      else
        log "Deary me, the bug report couldn't be submitted! Would you mind emailing these two files:"
        log '  ' + Base.task.var_path_for(dep_name)
        log '  ' + Base.task.log_path_for(dep_name)
        log "to ben@hoskings.net? Thanks."
      end
    end
  end
end
