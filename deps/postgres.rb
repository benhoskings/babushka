gem_dep 'db gem' do
  requires 'db software', 'rubygems'
  pkg 'pg'
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
  meet {
    render_erb 'postgres/offsite_backup.rb.erb', :to => '/usr/local/bin/postgres_offsite_backup', :perms => '755'
    sudo "ln -sf /usr/local/bin/postgres_offsite_backup /etc/cron.hourly/"
  }
end

pkg_dep 'db software' do
  pkg :macports => 'postgresql83-server', :apt => %w[postgresql postgresql-client libpq-dev]
  provides 'psql'
end
