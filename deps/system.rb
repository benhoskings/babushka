dep 'system' do
  requires 'secured ssh'
end

def ssh_conf_path file
  "../etc#{'/ssh' if linux?}/#{file}_config"
end

dep 'secured ssh' do
  requires 'sed'
  met? { failable_shell('ssh nonexistentuser@localhost').stderr['(publickey)']; nil }
  meet {
    change_with_sed 'StrictHostKeyChecking',           'yes', 'no', ssh_conf_path(:ssh)
    change_with_sed 'PasswordAuthentication',          'yes', 'no', ssh_conf_path(:sshd)
    change_with_sed 'ChallengeResponseAuthentication', 'yes', 'no', ssh_conf_path(:sshd)

    failable_shell "killall -HUP sshd"
  }
end
