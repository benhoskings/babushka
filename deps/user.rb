dep 'user setup' do
  requires 'user shell setup', 'ssh key'
  asks_for :username
end

dep 'user shell setup' do
  requires 'fish', 'dot files'
  met? {
    File.basename(shell("echo $SHELL")) == 'fish'
  }
  meet {
    sudo "chsh -s #{shell('which fish')} #{username}"
  }
end

dep 'ssh key' do
  requires 'user exists'
  asks_for :public_key
  met? {
    !failable_shell("grep '#{public_key}' ~/.ssh/authorized_keys").stdout.empty?
  }
  meet {
    shell 'mkdir -p ~/.ssh'
    append_to_file public_key, "~/.ssh/authorized_keys"
    shell 'chmod 700 ~/.ssh'
    shell 'chmod 600 ~/.ssh/authorized_keys'
  }
end

dep 'dot files' do
  requires 'user exists', 'git'
  met? {
    File.exists?(ENV['HOME'] / ".dot-files/.git")
  }
  meet {
    shell 'wget "http://github.com/benhoskings/dot-files/tree/master/clone_and_link.sh?raw=true" -O - | bash'
  }
end

dep 'user exists' do
  asks_for :username
  met? { shell("grep #{username} /etc/passwd") }
  meet {
    sudo "useradd #{username} -m -s /bin/bash"
    sudo "chmod 701 /home/#{username}"
  }
end
