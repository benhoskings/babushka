dep 'rubygems' do
  def version; '1.7.2' end
  requires 'ruby'
  requires_when_unmet 'curl.managed'
  met? {
    # We check for ruby here too to make sure `ruby` and `gem` run from the same place.
    in_path? ["gem #{version}", 'ruby']
  }
  meet {
    handle_source "http://production.cf.rubygems.org/rubygems/rubygems-#{version}.tgz" do
      shell "ruby setup.rb", :sudo => !File.writable?(which('ruby'))
    end
  }
  after {
    %w[cache ruby specs].each {|name| ('~/.gem' / name).mkdir }
  }
end
