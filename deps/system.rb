dep 'system' do
  requires 'hostname', 'secured ssh logins', 'lax host key checking', 'admins can sudo'
end

def ssh_conf_path file
  "/etc#{'/ssh' if linux?}/#{file}_config"
end

dep 'hostname' do
  met? {
    if osx?
      true
    else
      current_hostname = shell('hostname -f')
      stored_hostname = read_file('/etc/hostname')
      !stored_hostname.blank? && current_hostname == stored_hostname
    end
  }
  meet {
    if linux?
      sudo "echo #{hostname shell('hostname')} > /etc/hostname"
      sudo "sed -ri 's/^127.0.0.1.*$/127.0.0.1 #{hostname} localhost.localdomain localhost/' /etc/hosts"
      sudo "/etc/init.d/hostname.sh"
    end
  }
end

dep 'secured ssh logins' do
  requires 'sed'
  met? {
    returning failable_shell('ssh -o StrictHostKeyChecking=no nonexistentuser@localhost').stderr['(publickey)'] do |result|
      log_verbose "sshd #{'only ' if result}accepts #{result.scan(/[a-z]+/).to_list} logins.", :as => (result ? :ok : :error)
    end
  }
  meet {
    change_with_sed 'PasswordAuthentication',          'yes', 'no', ssh_conf_path(:sshd)
    change_with_sed 'ChallengeResponseAuthentication', 'yes', 'no', ssh_conf_path(:sshd)
  }
end

dep 'lax host key checking' do
  requires 'sed'
  met? { grep /^StrictHostKeyChecking[ \t]+no/, ssh_conf_path(:ssh) }
  meet { change_with_sed 'StrictHostKeyChecking', 'yes', 'no', ssh_conf_path(:ssh) }
end

dep 'admins can sudo' do
  requires 'admin group'
  met? { grep /^%admin/, '/etc/sudoers' }
  meet { append_to_file '%admin  ALL=(ALL) ALL', '/etc/sudoers' }
end

dep 'admin group' do
  met? { grep /^admin\:/, '/etc/group' }
  meet { shell "groupadd admin" }
end

dep 'build tools' do
  requires :osx => 'xcode tools', :linux => ['build-essential', 'autoconf']
end
