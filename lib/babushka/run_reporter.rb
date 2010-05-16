module Babushka
  class RunReporter
  class << self
    def report dep, result, reportable
      post_report dep.name, 'TODO', (reportable ? 'error' : (result ? 'ok' : 'fail'))
    end


    private

    def post_report dep_name, source_url, result
      require 'net/http'
      require 'uri'

      returning(Net::HTTP.post_form(
        URI.parse('http://next.babushka.me/runs.json'),
        {
          "dep_name" => dep_name,
          "source_url" => source_url,
          "result" => result
        }
      )) do |response|
        log "Anonymous report: #{response.class}: #{response.body}"
      end.is_a? Net::HTTPSuccess
    end

  end
  end
end
