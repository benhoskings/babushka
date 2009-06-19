dep 'user setup' do
  requires 'user shell setup', 'ssh key', 'dot files'
  asks_for :username
end

dep 'user shell setup' do
  requires 'fish'
  met? {
    File.basename(shell("echo $SHELL")) == 'fish'
  }
  meet {
    shell "chsh -s #{shell('which fish')}"
  }
end

dep 'ssh key' do
  requires 'user exists'
  met? {
    !shell("grep ben@hat ~ben/.ssh/authorized_keys").empty?
  }
  meet {
    shell 'mkdir ~/.ssh'
    shell 'echo "AAAAB3NzaC1kc3MAAACBAM2lpANrrRiLi9xnCl5rGFMsDeqEiXcQX3Y9UDchbsf5nH0JvNUKjNppVh3r+JTNOge3rHpNIBipzqqdtgwb7KL9JChvxcATkTye4ok0LfQJsYW3bcnJ1aQiIXeG5UEjRBfEgMNL/qhvhlQjUdkGFi23Jidx5qD8w+m3elUPVAo/AAAAFQCI52+Fed0JJm7zcGOfiz7993Z1JQAAAIBLmaM9/ZQ6a/x/fO+3A7dLT0cCxwpNtitkPc1fqFVvhTf3FB2G0U4DYBaPg9wNOCqcwcGZZtgl30I33MlAXJp8CUSxnnmkTmPJNs7D2YPuR9fwpj2khuF/UtiJAjkhZrdJ3WsA1/3caELIyZwYb/znbXENiH7/fx3sbIGdRRn/mAAAAIBi1TrUkWIhSPPyFh+9UJWYHNlLVwQfVhB/w+7kR8MIttJ2Yar4IJiRyIWzD+d5CEojqved/jYUxoDiTx5fN3xDCeMNK0z4z1767oyaXWWJs5XOPiCJsog9G/mBHcLGrYutFQusmPp2B3O96wfGsPJpCyQqtJ2qK8eeOMt9E27hPw== ben@hat" > ~/.ssh/authorized_keys'
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
  requires 'fish'
  met? { true || shell("grep ben /etc/passwd") }
  meet {
    sudo "useradd ben -m -s /usr/bin/fish"
    sudo "chmod 701 /home/ben"
    
    
  }
end