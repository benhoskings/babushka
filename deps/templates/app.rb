meta :app do
  accepts_list_for :source
  accepts_list_for :extra_source
  accepts_list_for :app_name, :name
  accepts_block_for :current_version
  accepts_block_for :latest_version

  template {
    helper :app_name_match do
      app_name.first.sub(/\.app$/, '*.app')
    end

    helper :check_version do |path|
      current = current_version.call(path)
      if current.nil? || version.nil?
        debug "Can't check versions without both current and latest."
      elsif current == version
        log_ok "#{name} is up to date at #{version}."
      else
        log "#{name} could be updated from #{current} to #{version}."
      end
    end

    prepare {
      setup_source_uris
    }

    met? {
      installed = Dir.glob("/Applications/#{app_name_match}").select {|entry|
        (entry / 'Contents/MacOS').exists?
      }
      returning installed.any? && check_version(installed.first) do |result|
        log "Found at #{installed.first}." if result
      end
    }

    meet {
      process_sources {|archive|
        matches = Dir.glob("**/#{app_name_match}").select {|entry|
          (entry / 'Contents/MacOS').exists? # must be an app bundle itself
        }.reject {|entry|
          entry['.app/'] # mustn't be inside another app bundle
        }.map {|entry|
          if archive.is_a? Babushka::DmgArchive
            log_block("Found #{entry} in the DMG, copying to /Applications") { FileUtils.cp_r entry, '/Applications/' }
          else
            log_block("Found #{entry}, moving to /Applications") { FileUtils.mv entry, '/Applications/' }
          end
        }
      }
    }
  }
end
