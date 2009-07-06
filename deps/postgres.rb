gem 'db gem' do
  requires 'db software'
  installs 'pg'
  provides []
end

dep 'db access' do
  requires 'db software', 'user exists'
  met? { !sudo("echo '\\du' | #{which 'psql'}", :as => 'postgres').split("\n").grep(/^\W*\b#{username shell('whoami')}\b/).empty? }
  meet { sudo "createuser -SdR #{username}", :as => 'postgres' }
end

dep 'db backups' do
  requires 'db software'
  asks_for :offsite_host
  met? {
    shell "test -x /etc/cron.hourly/postgres_offsite_backup"
  }
  before {
    returning sudo "ssh #{offsite_host} 'true'" do |result|
      if result
        log_ok "publickey login to #{offsite_host}"
      else
        log_error "You need to add root's public key to #{offsite_host}:~/.ssh/authorized_keys."
      end
    end
  }
  meet {
    render_erb 'postgres/offsite_backup.rb.erb', :to => '/usr/local/bin/postgres_offsite_backup', :perms => '755'
    sudo "ln -sf /usr/local/bin/postgres_offsite_backup /etc/cron.hourly/"
  }
end

pkg 'db software' do
  requires 'db in path'
  installs :macports => 'postgresql83-server', :apt => %w[postgresql postgresql-client libpq-dev]
  provides 'psql'
end

dep 'db in path', :for => :osx do
  met? { ENV['PATH'].split(':').include? '/opt/local/lib/postgresql83/bin' }
  meet {
    sudo "echo '/opt/local/lib/postgresql83/bin' > /etc/paths.d/postgres"
    ENV['PATH'] = "/opt/local/lib/postgresql83/bin:#{ENV['PATH']}"
  }
end
