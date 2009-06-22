dep 'www user and group' do
  www_name = osx? ? '_www' : 'www'
  met? { grep(/^#{www_name}\:/, '/etc/passwd') and grep(/^#{www_name}\:/, '/etc/group') }
  meet {
    shell "groupadd #{www_name}"
    shell "useradd -g #{www_name} #{www_name} -s /bin/false"
  }
end
