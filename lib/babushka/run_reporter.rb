module Babushka
  class RunReporter
  class << self
    def report dep, result, reportable
      if dep.dep_source.type != :public
        debug "Not reporting #{dep.contextual_name}, since it's not in a public source."
      else
        post_report dep, (reportable ? 'error' : (result ? 'ok' : 'fail'))
      end
    end


    private

    def post_report dep, result
      require 'net/http'
      require 'uri'

      returning(Net::HTTP.post_form(
        URI.parse('http://babushka.me/runs.json'),
        Base.task.task_info(dep, result)
      )) do |response|
        log "Anonymous report: #{response.class}: #{response.body}"
      end.is_a? Net::HTTPSuccess
    end

  end
  end
end
