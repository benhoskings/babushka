dep 'system' do
  requires 'secured ssh logins', 'lax host key checking'
end

def ssh_conf_path file
  "/etc#{'/ssh' if linux?}/#{file}_config"
end

dep 'secured ssh logins' do
  requires 'sed'
  met? {
    returning failable_shell('ssh nonexistentuser@localhost').stderr['(publickey)'] do |result|
      log_verbose "sshd #{'only ' if result}accepts #{result.scan(/[a-z]+/).to_list} logins.", :as => (result ? :ok : :error)
    end
  }
  meet {
    change_with_sed 'PasswordAuthentication',          'yes', 'no', ssh_conf_path(:sshd)
    change_with_sed 'ChallengeResponseAuthentication', 'yes', 'no', ssh_conf_path(:sshd)

    # failable_shell "killall -HUP sshd"
  }
end

dep 'lax host key checking' do
  requires 'sed'
  met? {
    failable_shell("grep '^StrictHostKeyChecking[ \\t]\\+no' #{ssh_conf_path(:ssh)}").stdout.empty? ? nil : true
  }
  meet {
    change_with_sed 'StrictHostKeyChecking', 'yes', 'no', ssh_conf_path(:ssh)
    # failable_shell "killall -HUP sshd"
  }
end
