module Babushka
  class RunReporter
  class << self
    include LogHelpers

    def queue dep, result, reportable
      if dep.dep_source.type != :public
        debug "Not reporting #{dep.contextual_name}, since it's not in a public source."
      else
        queue_report dep, (reportable ? 'error' : (result ? 'ok' : 'fail'))
      end
    end

    def post_reports
      require 'net/http'

      while Base.task.running? && (report = most_recent_report)
        post_report report
        sleep 1 # A quick hack for now, so we don't dominate the railscamp server.
      end
    end


    private

    def post_report report
      submit_report_to_webservice(report.p.read).tap {|result|
        report.p.rm if result
      }
    end

    require 'net/http'
    def submit_report_to_webservice data
      Net::HTTP.start('babushka.me') {|http|
        http.open_timeout = http.read_timeout = 5
        http.post '/runs.json', data
      }.is_a?(Net::HTTPSuccess)
    rescue Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED, SocketError
      log_error "Couldn't connect to the babushka webservice." unless Base.task.running?
    rescue Timeout::Error, Errno::ETIMEDOUT
      debug "Timeout while submitting run report."
    end

    def most_recent_report
      ReportPrefix.p.glob('*').sort.last
    end

    def queue_report dep, result
      ReportPrefix.p.mkdir
      (ReportPrefix / Time.now.to_f).open('w') {|f|
        f << run_report_for(dep, result).to_http_params
      }
    end

    def run_report_for dep, result
      Base.task.task_info(dep, result)
    end

  end
  end
end
