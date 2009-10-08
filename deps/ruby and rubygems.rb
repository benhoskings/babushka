dep 'rubygems' do
  requires 'rubygems installed', 'github source'
  setup {
    shell('ruby --version')['ruby 1.9'].nil? || definer.requires('fake json gem')
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

dep 'github source' do
  requires 'rubygems installed'
  met? { shell("gem sources")["http://gems.github.com"] }
  meet { sudo "gem sources -a http://gems.github.com" }
end

dep 'rubygems installed' do
  requires 'ruby', 'curl'
  merge :versions, :rubygems => '1.3.5'
  met? { cmds_in_path? 'gem', cmd_dir('ruby') }
  meet {
    in_build_dir {
      get_source("http://rubyforge.org/frs/download.php/60718/rubygems-#{var(:versions)[:rubygems]}.tgz") and

      in_dir "rubygems-#{var(:versions)[:rubygems]}" do
        sudo "ruby setup.rb"
      end
    }
  }
  after {
    in_dir cmd_dir('ruby') do
      sudo "ln -sf gem1.8 gem" if File.exists?('gem1.8')
    end
  }
end

dep 'ruby' do
  setup {
    rubies = {
      'pkg' => "Install via #{Babushka::PkgHelper.for_system.manager_dep}",
      'ree' => "Build Ruby Enterprise Edition from source"
    }
    rubies['system'] = "Use the OS X-supplied version" if host.osx?
    chosen_ruby = sticky_var(:ruby_type,
      :message => "Which ruby would you like to use",
      :choice_descriptions => rubies,
      :default => 'pkg'
    )
    requires "#{chosen_ruby} ruby"
  }
end

pkg 'pkg ruby' do
  installs {
    via :macports, 'ruby'
    via :brew, 'ruby'
    via :apt, %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  }
  provides %w[ruby irb ri rdoc]
end

dep 'system ruby', :for => :osx do
  met? {
    cmds_in_path? ['ruby', 'irb', 'ri', 'rdoc']
  }
end

src 'ree ruby' do
  source "http://rubyforge.org/frs/download.php/64475/ruby-enterprise-1.8.7-20090928.tar.gz"
  provides 'ruby', 'irb', 'ri', 'rdoc'
  met? {
    log_error "Not implemented yet - bug me on twitter (@ben_h) or even better, send me your dep :)"
    :fail
  }
end

pkg 'ruby 1.9' do
  installs {
    via :macports, 'ruby19'
    via :apt, %w[ruby1.9 irb1.9 ri1.9 rdoc1.9 ruby1.9-dev libopenssl-ruby1.9]
  }
  provides %w[ruby1.9 irb1.9 ri1.9 rdoc1.9]
end
