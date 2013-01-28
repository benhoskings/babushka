{
  'curl.managed'    => 'curl.bin',
  'gettext.managed' => 'gettext.lib',
  'git.managed'     => 'git.bin',
  'pip.managed'     => 'pip.bin',
  'ruby.managed'    => 'ruby',
  'sudo.managed'    => 'sudo.bin',
  'sudo'            => 'sudo.bin'
}.each_pair {|old_name, new_name|

  dep old_name do
    removed! :method_name => "'#{name}'", :callpoint => false, :instead => "the '#{new_name}' dep"
  end

}
