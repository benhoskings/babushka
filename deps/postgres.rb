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
  on :osx, after {
    shell "mkdir -p #{pkg_manager.prefix / 'var/db/postgres/8.4/defaultdb'}" and
    shell "ln -sf #{pkg_manager.prefix / 'var/db/postgres/8.4/defaultdb'} #{pkg_manager.prefix / 'var/postgres'}" and
    shell "#{pkg_manager.bin_path / 'initdb'} -D #{pkg_manager.prefix / 'var/postgres'}" and
    shell "launchctl load -w /usr/local/Cellar/postgresql/8.4.0/org.postgresql.postgres.plist"
  }
end
