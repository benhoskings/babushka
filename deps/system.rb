dep 'system' do
  requires 'secured ssh logins', 'lax host key checking'
end

def ssh_conf_path file
  "/etc#{'/ssh' if linux?}/#{file}_config"
end

dep 'secured ssh logins' do
  requires 'sed'
  met? { failable_shell('ssh nonexistentuser@localhost').stderr['(publickey)'] }
  meet {
    change_with_sed 'PasswordAuthentication',          'yes', 'no', ssh_conf_path(:sshd)
    change_with_sed 'ChallengeResponseAuthentication', 'yes', 'no', ssh_conf_path(:sshd)

    failable_shell "killall -HUP sshd"
  }
end

dep 'lax host key checking' do
  requires 'sed'
  met? {
    failable_shell("grep '^StrictHostKeyChecking[ \\t]\\+no' #{ssh_conf_path(:ssh)}").stdout.empty? ? nil : true
  }
  meet {
    change_with_sed 'StrictHostKeyChecking', 'yes', 'no', ssh_conf_path(:ssh)
    failable_shell "killall -HUP sshd"
  }
end
