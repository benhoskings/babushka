dep 'rubygems' do
  requires 'rubygems installed', 'github source'
end

dep 'github source' do
  requires 'rubygems installed'
  met? { shell("gem sources")["http://gems.github.com"] }
  meet { sudo "gem sources -a http://gems.github.com" }
end

dep 'rubygems installed' do
  requires 'ruby', 'curl'
  met? {
    if which('gem').nil?
      unmet "'gem' is not installed"
    elsif cmd_dir('gem') != cmd_dir('ruby')
      unmet "'gem' incorrectly runs from #{cmd_dir('gem')}"
    else
      shell 'gem env gemdir'
    end
  }
  meet {
    rubygems_version = '1.3.5'

    in_build_dir {
      get_source("http://rubyforge.org/frs/download.php/60718/rubygems-#{rubygems_version}.tgz") and

      in_dir "rubygems-#{rubygems_version}" do
        sudo "ruby setup.rb"
      end

      in_dir cmd_dir('ruby') do
        sudo "ln -sf gem1.8 gem" if File.exists?('gem1.8')
      end
    }
  }
end

pkg 'ruby' do
  installs {
    macports 'ruby'
    apt %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  }
  provides %w[ruby irb ri rdoc]
end


pkg 'ruby 1.9' do
  installs {
    macports 'ruby19'
    apt %w[ruby1.9 irb1.9 ri1.9 rdoc1.9 ruby1.9-dev libopenssl-ruby1.9]
  }
  provides %w[ruby1.9 irb1.9 ri1.9 rdoc1.9]
end
