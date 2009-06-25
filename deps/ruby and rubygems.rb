dep 'rubygems' do
  requires 'ruby'
  met? { which('gem') && shell('gem env gemdir') }
  meet {
    rubygems_version = '1.3.4'

    in_dir "~/src" do
      # disable ri and rdoc generation
      shell "sed -i 's/# gem\: --no-rdoc --no-ri/gem\: --no-rdoc --no-ri/' ~/.dot-files/.gemrc"
      shell "wget http://rubyforge.org/frs/download.php/57643/rubygems-#{rubygems_version}.tgz"
      shell "tar -zxvf rubygems-#{rubygems_version}.tgz"
      shell "cd rubygems-#{rubygems_version}"
      sudo "ruby setup.rb"

      in_dir cmd_dir('ruby') do
        sudo "ln -s gem1.8 gem"
      end
    end
  }
end

pkg_dep 'ruby' do
  pkg :macports => 'ruby', :apt => %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  provides %w[ruby irb ri rdoc]
end
