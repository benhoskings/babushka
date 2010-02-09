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
        true
      elsif current == version
        log_ok "#{name} is up to date at #{version}."
      else
        log "#{name} could be updated from #{current} to #{version}."
      end
    end

    helper :discover_latest_version do
      latest_value = latest_version.call
      # TODO this is just to detect the default block and ignore it. Yuck :)
      set_version latest_value unless latest_value == true
    end

    prepare {
      setup_source_uris
    }

    met? {
      discover_latest_version
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
          target_path = '/Applications' / entry
          if !target_path.exists? || confirm("Overwrite #{target_path}?") { FileUtils.rm_r target_path }
            if archive.is_a? Babushka::DmgArchive
              log_block("Found #{entry} in the DMG, copying to /Applications") { FileUtils.cp_r entry, '/Applications/' }
            else
              log_block("Found #{entry}, moving to /Applications") { FileUtils.mv entry, '/Applications/' }
            end
          end
        }
      }
    }
  }
end
