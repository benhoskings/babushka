meta :installer do
  accepts_list_for :source
  accepts_list_for :extra_source
  accepts_list_for :provides, :name, :choose_with => :via
  accepts_list_for :pkg_name, :name

  template {
    helper :current_version? do
      (provides & var(:versions).keys).all? {|p|
        shell("#{p} --version").split(/[\s\-]/).include? var(:versions)[p.to_s]
      }
    end

    prepare { setup_source_uris }
    met? { provided? and current_version? }

    # At the moment, we just try to install every .[m]pkg in the archive. If that's not
    # what you want, specify the name of the pkg to choose from the archive using
    # the +pkg_name+ method when you define your dep:
    #
    # dep 'blah.installer' do
    #   source 'http://blah.org/blah-latest.dmg
    #   pkg_name 'blah-1.7.0.pkg'
    #   provides 'blah' # Only required if the name isn't 'blah'
    # end
    #
    meet {
      process_sources {|archive|
        Dir.glob("**/*pkg").select {|entry|
          entry[/\.m?pkg$/] # Everything ending in .pkg or .mpkg
        }.reject {|entry|
          entry[/\.m?pkg\//] # and isn't inside another package
        }.map {|entry|
          log_shell "Installing #{entry}", "installer -target / -pkg '#{entry}'", :sudo => true
        }
      }
    }
  }
end
