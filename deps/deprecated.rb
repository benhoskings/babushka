{
  'curl'    => 'bin',
  'gettext' => 'lib',
  'git'     => 'bin',
  'pip'     => 'bin',
  'ruby'    => 'bin',
  'sudo'    => 'bin'
}.each_pair {|basename, new_template|

  dep "#{basename}.managed" do
    deprecated! "2012-11-14", :method_name => "'#{name}'", :callpoint => false, :instead => "the '#{basename}.#{new_template}' dep"
    requires "#{basename}.#{new_template}"
  end

}
