require 'rexml/document'
require 'net/http'

meta :app do
  accepts_list_for :source
  accepts_list_for :prefix, %w[~/Applications /Applications]
  accepts_list_for :extra_source
  accepts_list_for :provides, :name
  accepts_block_for :current_version do |path| nil end
  accepts_block_for :latest_version
  accepts_list_for :sparkle

  def app_name_match
    provides.first.to_s.sub(/\.app$/, '*.app')
  end

  def check_version path
    current = current_version.call(path)
    if current.nil? || version.nil?
      debug "Can't check versions without both current and latest."
      true
    elsif current >= version
      log_ok "#{name} is up to date at #{current}."
    else
      log "#{name} could be updated from #{current} to #{version}."
    end
  end

  def prefix_to_use
    prefix.map(&:p).find {|pre|
      pre.directory?
    } || '/Applications'.p
  end

  def discover_latest_version
    latest_value = latest_version.call
    # TODO this is just to detect the default block and ignore it. Yuck :)
    set_version latest_value unless latest_value == true
  end

  def get_source_from_sparkle
    sparkle_url = sparkle.first
    puts 'Fetching via sparkle at ' + sparkle_url
    url = URI.parse(sparkle_url)
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    doc = REXML::Document.new res.body
    [doc.elements['rss/channel/item/enclosure'].attributes['url']]
  end

  template {
    prepare {
      unless sparkle.empty?
        def source
          get_source_from_sparkle
        end
      end
      setup_source_uris
    }

    met? {
      discover_latest_version
      installed = app_dir app_name_match
      (installed && check_version(installed)).tap {|result|
        log "Found at #{installed}." if result
      }
    }

    meet {
      process_sources {|archive|
        matches = Dir.glob("**/#{app_name_match}").select {|entry|
          (entry / 'Contents/MacOS').exists? # must be an app bundle itself
        }.reject {|entry|
          entry['.app/'] # mustn't be inside another app bundle
        }.map {|entry|
          pre = prefix_to_use
          target_path = pre / File.basename(entry)
          if !target_path.exists? || confirm("Overwrite #{target_path}?") { target_path.rm }
            log_block("Found #{entry}, copying to #{pre}") {
              entry.p.copy target_path
            }
          end
        }
      }
    }
  }
end
