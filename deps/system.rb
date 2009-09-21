def ssh_conf_path file
  "/etc#{'/ssh' if linux?}/#{file}_config"
end

dep 'hostname', :for => :linux do
  met? {
    stored_hostname = read_file('/etc/hostname')
    !stored_hostname.blank? && hostname == stored_hostname
  }
  meet {
    sudo "echo #{var :hostname, :default => shell('hostname')} > /etc/hostname"
    sudo "sed -ri 's/^127.0.0.1.*$/127.0.0.1 #{hostname} localhost.localdomain localhost/' /etc/hosts"
    sudo "/etc/init.d/hostname.sh"
  }
end

dep 'secured ssh logins' do
  requires 'sshd', 'sed'
  met? {
    auth_methods = failable_shell('ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no nonexistentuser@localhost').stderr.scan(/\((.*)\)/).first.first.split(/[^a-z]+/)
    returning auth_methods == %w[publickey] do |result|
      log_verbose "sshd #{'only ' if result}accepts #{auth_methods.to_list} logins.", :as => (result ? :ok : :error)
    end
  }
  meet {
    change_with_sed 'PasswordAuthentication',          'yes', 'no', ssh_conf_path(:sshd)
    change_with_sed 'ChallengeResponseAuthentication', 'yes', 'no', ssh_conf_path(:sshd)
  }
  after { sudo "/etc/init.d/ssh restart" }
end

dep 'lax host key checking' do
  requires 'sed'
  met? { grep /^StrictHostKeyChecking[ \t]+no/, ssh_conf_path(:ssh) }
  meet { change_with_sed 'StrictHostKeyChecking', 'yes', 'no', ssh_conf_path(:ssh) }
end

dep 'admins can sudo' do
  requires 'admin group'
  met? { !sudo('cat /etc/sudoers').split("\n").grep(/^%admin/).empty? }
  meet { append_to_file '%admin  ALL=(ALL) ALL', '/etc/sudoers' }
end

dep 'admin group' do
  met? { grep /^admin\:/, '/etc/group' }
  meet { shell "groupadd admin" }
end

dep 'build tools' do
  requires {
    osx 'xcode tools'
    linux ['build-essential', 'autoconf']
  }
end

dep 'tmp cleaning grace period', :for => :linux do
  met? { !grep(/^[^#]*TMPTIME=0/, "/etc/default/rcS") }
  meet { change_line "TMPTIME=0", "TMPTIME=30", "/etc/default/rcS" }
end
