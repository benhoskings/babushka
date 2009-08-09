dep 'user shell setup' do
  requires 'fish', 'dot files'
  met? { File.basename(sudo('echo \$SHELL', :as => var(:username), :su => true)) == 'fish' }
  meet { sudo "chsh -s #{shell('which fish')} #{var(:username)}" }
end

dep 'passwordless ssh logins' do
  requires 'user exists'
  met? { grep your_ssh_public_key, '~/.ssh/authorized_keys' }
  meet {
    shell 'mkdir -p ~/.ssh'
    append_to_file your_ssh_public_key, "~/.ssh/authorized_keys"
    shell 'chmod 700 ~/.ssh'
    shell 'chmod 600 ~/.ssh/authorized_keys'
  }
end

dep 'public key' do
  met? { grep /^ssh-dss/, '~/.ssh/id_dsa.pub' }
  meet { shell("ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ''").tap_log }
end

dep 'dot files' do
  requires 'user exists', 'git'
  met? { File.exists?(ENV['HOME'] / ".dot-files/.git") }
  meet { shell 'wget "http://github.com/benhoskings/dot-files/tree/master/clone_and_link.sh?raw=true" -O - | bash' }
end

dep 'user exists' do
  met? { grep(/^#{var(:username)}:/, '/etc/passwd') }
  meet {
    sudo "useradd #{var(:username)} -m -s /bin/bash -G admin"
    sudo "chmod 701 /home/#{var(:username)}"
  }
end
