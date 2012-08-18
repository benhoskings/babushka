meta :app do
  accepts_list_for :source
  accepts_list_for :prefix, %w[~/Applications /Applications]
  accepts_value_for :provides, :name
  accepts_value_for :version, nil
  accepts_block_for :current_version do |path| nil end
  accepts_value_for :sparkle

  def app
    Babushka.VersionOf(provides, version)
  end

  def app_name_matcher
    app.name.sub(/\.app$/, '*.app')
  end

  def app_location
    prefix.find {|p|
      (p.to_s / app_name_matcher).glob.select {|entry|
        (entry / 'Contents/MacOS').exists?
      }.first
    }
  end

  def prefix_to_use
    prefix.map(&:p).find(&:directory?) || '/Applications'.p
  end

  def app_in_path?
    app_location.tap {|path|
      if path
        log "Found #{app.name} in #{path}."
      else
        log "Couldn't find #{provides}."
      end
    }
  end

  def get_source_from_sparkle
    require 'rexml/document'
    require 'net/http'

    sparkle_url = log_block 'Querying sparkle' do
      url = URI.parse(sparkle)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.get(url.path)
      }
      doc = REXML::Document.new(res.body)
      doc.elements['rss/channel/item/enclosure'].attributes['url']
    end

    [sparkle_url]
  end

  template {
    prepare {
      unless sparkle.blank?
        def source
          get_source_from_sparkle
        end
      end
      setup_source_uris
    }

    met? {
      app_in_path? and
      Babushka::PathChecker.matching_versions?([app]) {|cmd|
        current_version.call(app_location / provides)
      }
    }

    meet {
      process_sources {|archive|
        Dir.glob("**/#{app_name_matcher}").select {|entry|
          (entry / 'Contents/MacOS').exists? # must be an app bundle itself
        }.reject {|entry|
          entry['.app/'] # mustn't be inside another app bundle
        }.map {|entry|
          pre = prefix_to_use
          target_path = pre / File.basename(entry)
          log_block("Found #{entry}, copying to #{pre}") {
            if !target_path.exists? || confirm("Overwrite #{target_path}?") { target_path.rm }
              entry.p.copy target_path
            end
          }
        }
      }
    }
  }
end
