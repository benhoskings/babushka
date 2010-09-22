module Babushka
  class RunReporter
  class << self
    def report dep, result, reportable
      post_report dep, (reportable ? 'error' : (result ? 'ok' : 'fail'))
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
