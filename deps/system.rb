dep 'system' do
  requires 'hostname', 'correct path', 'secured ssh logins', 'lax host key checking', 'admins can sudo'
end

def ssh_conf_path file
  "/etc#{'/ssh' if linux?}/#{file}_config"
end

dep 'correct path', :for => :osx do
  requires 'correct path order', 'path_helper fish support'
end

dep 'correct path order' do
  met? { grep %Q(NEWPATH="${p}${SEP}${NEWPATH}"), '/usr/libexec/path_helper' }
  meet {
    change_line %Q(NEWPATH="${NEWPATH}${SEP}${p}"), %Q(NEWPATH="${p}${SEP}${NEWPATH}"), '/usr/libexec/path_helper'
    ENV['PATH'] = "/opt/local/bin:#{ENV['PATH']}" if osx? # TODO: hax
  }
end

dep 'path_helper fish support' do
  met? { grep %Q(path_helper [-c | -f | -s]), "/usr/libexec/path_helper" }
  meet {
    change_line %Q(echo "usage: path_helper [-c | -s]" 1>&2), %Q(echo "usage: path_helper [-c | -f | -s]" 1>&2), '/usr/libexec/path_helper'
    insert_into_file 'exit 0', 'elif [ "$1" == "-s" -o -z "$1" ]; then', '/usr/libexec/path_helper',
      %q{elif [ "$1" == "-f" -o \( -z "$1" -a "${SHELL%fish}" != "$SHELL" \) ]; then
	echo set -x PATH $P | tr ':' ' '
	echo set -x MANPATH $MP | tr ':' ' '
	exit 0}
  }
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
