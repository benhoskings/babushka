dep 'www user and group' do
  www_name = osx? ? '_www' : 'www'
  met? { grep(/^#{www_name}\:/, '/etc/passwd') and grep(/^#{www_name}\:/, '/etc/group') }
  meet {
    sudo "groupadd #{www_name}"
    sudo "useradd -g #{www_name} #{www_name} -s /bin/false"
  }
end
