dep 'rubygems', :version do
  version.default!('1.8.10')
  requires 'ruby'
  requires_when_unmet 'curl.managed'
  met? {
    # We check for ruby here too to make sure `ruby` and `gem` run from the same place.
    in_path? ["gem >= #{version}", 'ruby']
  }
  meet {
    handle_source "http://production.cf.rubygems.org/rubygems/rubygems-#{version}.tgz" do
      log_shell "Installing rubygems-#{version}", "ruby setup.rb", :spinner => true, :sudo => !File.writable?(which('ruby'))
    end
  }
  after {
    %w[cache ruby specs].each {|name| ('~/.gem' / name).mkdir }
    cd cmd_dir('ruby') do
      %w[gem1.8 gem18].each do |file|
        if File.exists? file
          shell "ln -sf #{file} gem", :sudo => !File.writable?(which('ruby'))
          break
        end
      end
    end
  }
end
