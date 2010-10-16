dep 'rubygems' do
  requires 'rubygems up to date'
  setup {
    definer.requires('fake json gem') if shell('ruby --version')['ruby 1.9']
  }
  after {
    %w[cache ruby specs].each {|name| ('~/.gem' / name).mkdir }
  }
end

dep 'fake json gem' do
  met? { Babushka::GemHelper.has? 'json' }
  meet {
    log "json is now included in ruby core, and when gems try to install the"
    log "gem, it fails to build. So, let's install a fake version of json-1.1.9."
    in_build_dir {
      log_block "Generating fake json-1.1.9 gem" do
        File.open 'fake_json.gemspec', 'w' do |f|
          f << %Q{
            spec = Gem::Specification.new do |s|
              s.name = "json"
              s.version = "1.1.9"
              s.summary = "this fakes json (which is now included in stdlib)"
              s.homepage = "http://gist.github.com/gists/58071"
              s.has_rdoc = false
              s.required_ruby_version = '>= 1.9.1'
            end
          }
        end
        shell "gem build fake_json.gemspec"
      end
      Babushka::GemHelper.install! 'json-1.1.9.gem', '--no-ri --no-rdoc'
    }
  }
end

dep 'rubygems up to date' do
  requires 'rubygems installed'
  met? { Babushka::GemHelper.version >= var(:versions)[:rubygems] }
  meet {
    log_block "Updating the rubygems install in #{which('gem').p.parent}" do
      Babushka::GemHelper.update!
    end
  }
end

dep 'rubygems installed' do
  requires 'ruby'
  requires_when_unmet 'curl.managed'
  merge :versions, :rubygems => '1.3.7'
  met? { provided? %w[gem ruby] }
  meet {
    handle_source "http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz" do
      shell "ruby setup.rb", :sudo => !File.writable?(which('ruby'))
    end
  }
  after {
    in_dir cmd_dir('ruby') do
      if File.exists? 'gem1.8'
        shell "ln -sf gem1.8 gem", :sudo => !File.writable?(which('ruby'))
      end
    end
  }
end
