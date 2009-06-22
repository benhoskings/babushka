dep 'www user and group' do
  group_name = osx? ? '_www' : 'www'
  met? { grep(/^#{group_name}\:/, '/etc/passwd') and grep(/^#{group_name}\:/, '/etc/group') }
  meet { shell "useradd -g #{group_name} #{group_name} -s /bin/false" }
end
