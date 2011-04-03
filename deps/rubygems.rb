dep 'rubygems' do
  requires 'rubygems up to date'
  after {
    %w[cache ruby specs].each {|name| ('~/.gem' / name).mkdir }
  }
end

dep 'rubygems up to date' do
  requires 'rubygems installed'
  met? { Babushka::GemHelper.version >= '1.3.7' }
  meet {
    log_block "Updating the rubygems install in #{which('gem').p.parent}" do
      Babushka::GemHelper.update!
    end
  }
end

dep 'rubygems installed' do
  requires 'ruby'
  requires_when_unmet 'curl.managed'
  met? { in_path? %w[gem ruby] }
  meet {
    handle_source "http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz" do
      shell "ruby setup.rb", :sudo => !File.writable?(which('ruby'))
    end
  }
  after {
    cd cmd_dir('ruby') do
      if File.exists? 'gem1.8'
        shell "ln -sf gem1.8 gem", :sudo => !File.writable?(which('ruby'))
      end
    end
  }
end
