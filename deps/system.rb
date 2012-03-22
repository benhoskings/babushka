dep 'admins can sudo' do
  requires 'admin group', 'sudo'
  met? { !sudo('cat /etc/sudoers').split("\n").grep(/^%admin/).empty? }
  meet { append_to_file '%admin  ALL=(ALL) ALL', '/etc/sudoers', :sudo => true }
end

dep 'admin group' do
  met? { '/etc/group'.p.grep(/^admin\:/) }
  meet { sudo 'groupadd admin' }
end
