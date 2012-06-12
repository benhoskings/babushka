{
  'curl.managed'    => 'curl.bin',
  'gettext.managed' => 'gettext.lib',
  'git.managed'     => 'git.bin',
  'pip.managed'     => 'pip.bin',
  'ruby.managed'    => 'ruby.bin',
  'sudo.managed'    => 'sudo.bin'
}.each_pair {|old_name, new_name|

  dep old_name do
    deprecated! "2012-11-14", :method_name => "'#{name}'", :callpoint => false, :instead => "the '#{new_name}' dep"
    requires new_name
  end

}
