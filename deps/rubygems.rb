dep 'rubygems' do
  def version; '1.8.10' end
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
      if File.exists? 'gem1.8'
        shell "ln -sf gem1.8 gem", :sudo => !File.writable?(which('ruby'))
      end
    end
  }
end
