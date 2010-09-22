module Babushka
  RunReportQueue = '~/.babushka/runs'

  class RunReporter
  class << self
    def queue dep, result, reportable
      if dep.dep_source.type != :public
        debug "Not reporting #{dep.contextual_name}, since it's not in a public source."
      else
        queue_report dep, (reportable ? 'error' : (result ? 'ok' : 'fail'))
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

    def queue_report dep, result
      RunReportQueue.p.open('a') {|f|
        f << sanitised_run_report_for(dep, result)
      }
    end

    def sanitised_run_report_for dep, result
      run_report_for(dep, result).inspect.gsub("\n", ' ').end_with("\n")
    end

    def run_report_for dep, result
      Base.task.task_info(dep, result)
    end

  end
  end
end
