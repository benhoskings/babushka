# template for os x applications
meta :app do
  # the URI from where to fetch the application. This can be git, tar, ziped or whatever
  accepts_list_for :source
  # the directory to install the applicaiton in. First first existing directory is taken.
  accepts_list_for :prefix, %w[~/Applications /Applications]
  accepts_list_for :extra_source
  # the executable that should be available if the dep is met
  accepts_list_for :provides, :name
  accepts_block_for :current_version do |path| nil end
  accepts_block_for :latest_version

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

  # use the first string from the prefix array that is an existing directory 
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

  template {
    prepare {
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
