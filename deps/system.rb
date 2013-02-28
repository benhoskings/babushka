dep 'admins can sudo' do
  requires 'admin group', 'sudo.bin'
  met? { !sudo('cat /etc/sudoers').split("\n").grep(/^%admin/).empty? }
  meet { '/etc/sudoers'.p.append("%admin  ALL=(ALL) ALL") }
end

dep 'admin group' do
  met? { '/etc/group'.p.grep(/^admin\:/) }
  meet { sudo 'groupadd admin' }
end
