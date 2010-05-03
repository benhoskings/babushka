meta :app do
  accepts_list_for :source
  accepts_list_for :prefix, ['/Applications']
  accepts_list_for :extra_source
  accepts_list_for :provides, :name
  accepts_block_for :current_version do |path| nil end
  accepts_block_for :latest_version

  template {
    helper :app_name_match do
      provides.first.sub(/\.app$/, '*.app')
    end

    helper :check_version do |path|
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
      installed = app_dir app_name_match
      returning installed && check_version(installed) do |result|
        log "Found at #{installed}." if result
      end
    }

    meet {
      process_sources {|archive|
        matches = Dir.glob("**/#{app_name_match}").select {|entry|
          (entry / 'Contents/MacOS').exists? # must be an app bundle itself
        }.reject {|entry|
          entry['.app/'] # mustn't be inside another app bundle
        }.map {|entry|
          prefix.each {|pre|
            pre = pre.to_s # TODO shouldn't be required once accepts_list_for is more generic
            target_path = pre / entry
            if !target_path.exists? || confirm("Overwrite #{target_path}?") { FileUtils.rm_r target_path }
              if archive.is_a? Babushka::DmgArchive
                log_block("Found #{entry} in the DMG, copying to #{pre}") {
                  shell "cp -a '#{entry}' '#{pre.end_with('/')}'"
                }
              else
                log_block("Found #{entry}, moving to #{pre}") { FileUtils.mv entry, pre.end_with('/') }
              end
            end
          }
        }
      }
    }
  }
end
