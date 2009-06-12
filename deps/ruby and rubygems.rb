# rubygems should be installed alongside ruby. We pretend ruby is a
# package manager here in order to use PkgManager#cmd_in_path?, which
# checks that the given command is alongside the 'package manager'
# (ruby in this case).
class RubyManager < PkgManager
  def pkg_cmd; 'ruby' end
end

dep 'rubygems' do
  requires 'ruby'
  met? { RubyManager.new.cmd_in_path?('gem') }
  meet {
    # TODO download/build/install rubygems
  }
end

pkg_dep 'ruby' do
  pkg :macports => 'ruby', :apt => %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  provides %w[ruby irb ri rdoc]
end
