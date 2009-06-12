dep 'rubygems' do
  requires 'ruby'
  met? {
    which('gem') &&
    cmd_dir('gem') == cmd_dir('ruby')
  }
  meet {
    
  }
end

pkg_dep 'ruby' do
  pkg :macports => 'ruby', :apt => %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  provides %w[ruby irb ri rdoc]
end
