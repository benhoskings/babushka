dep 'rubygems' do
  requires 'ruby', 'wget'
  met? { which('gem') && shell('gem env gemdir') }
  meet {
    rubygems_version = '1.3.4'

    in_dir "~/src", :create => true do
      # disable ri and rdoc generation
      change_line "# gem: --no-rdoc --no-ri", "gem: --no-rdoc --no-ri", '~/.dot-files/.gemrc'
      get_source("http://rubyforge.org/frs/download.php/57643/rubygems-#{rubygems_version}.tgz") and

      in_dir "rubygems-#{rubygems_version}" do
        sudo "ruby setup.rb"
      end

      in_dir cmd_dir('ruby') do
        sudo "ln -sf gem1.8 gem"
      end
    end
  }
end

pkg 'ruby' do
  installs :macports => 'ruby', :apt => %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  provides %w[ruby irb ri rdoc]
end

pkg 'ruby 1.9' do
  installs :macports => 'ruby19', :apt => %w[ruby1.9 irb1.9 ri1.9 rdoc1.9 ruby1.9-dev libopenssl-ruby1.9]
  provides %w[ruby1.9 irb1.9 ri1.9 rdoc1.9]
end
