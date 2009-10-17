dep 'existing postgres db' do
  requires 'postgres gem', 'postgres access'
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{var :db_name}\s+\|/)
    }.empty?
  }
  meet {
    shell "createdb -O '#{var :username}' '#{var :db_name}'"
  }
end

gem 'postgres gem' do
  requires 'postgres software'
  installs 'pg'
  provides []
end

dep 'postgres access' do
  requires 'postgres software', 'user exists'
  met? { !sudo("echo '\\du' | #{which 'psql'}", :as => 'postgres').split("\n").grep(/^\W*\b#{var :username}\b/).empty? }
  meet { sudo "createuser -SdR #{var :username}", :as => 'postgres' }
end

dep 'postgres backups' do
  requires 'postgres software'
  met? { shell "test -x /etc/cron.hourly/postgres_offsite_backup" }
  before {
    returning sudo "ssh #{var :offsite_host} 'true'" do |result|
      if result
        log_ok "publickey login to #{var :offsite_host}"
      else
        log_error "You need to add root's public key to #{var :offsite_host}:~/.ssh/authorized_keys."
      end
    end
  }
  meet {
    render_erb 'postgres/offsite_backup.rb.erb', :to => '/usr/local/bin/postgres_offsite_backup', :perms => '755', :sudo => true
    sudo "ln -sf /usr/local/bin/postgres_offsite_backup /etc/cron.hourly/"
  }
end

pkg 'postgres software' do
  installs {
    via :macports, 'postgresql83-server'
    via :apt, %w[postgresql postgresql-client libpq-dev]
    via :brew, 'postgresql'
  }
  provides 'psql'
  on :osx, after do
    sudo "ln -s #{Babushka::MacportsHelper.prefix / "lib/postgresql83/bin/*"} #{Babushka::MacportsHelper.prefix / 'bin/'}"

    sudo "mkdir -p /opt/local/var/db/postgresql83/defaultdb" and
    sudo "chown postgres:postgres /opt/local/var/db/postgresql83/defaultdb" and
    sudo "su postgres -c '/opt/local/lib/postgresql83/bin/initdb -D /opt/local/var/db/postgresql83/defaultdb'" and
    sudo "launchctl load -w /Library/LaunchDaemons/org.macports.postgresql83-server.plist"
  end
end
