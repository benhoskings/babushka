gem 'mysql gem' do
  requires 'mysql software'
  installs 'mysql'
  provides []
end

dep 'mysql access' do
  requires 'mysql db exists'
  define_var :db_user, :default => :username
  define_var :db_host, :default => 'localhost'
  met? { mysql "use #{var(:db_name)}", var(:db_user) }
  meet { mysql %Q{GRANT ALL PRIVILEGES ON #{var :db_name}.* TO '#{var :db_user}'@'#{var :db_host}' IDENTIFIED BY '#{var :db_password}'} }
end

dep 'mysql db exists' do
  requires 'mysql configured'
  met? { mysql("SHOW DATABASES").split("\n")[1..-1].any? {|l| /\b#{var :db_name}\b/ =~ l } }
  meet { mysql "CREATE DATABASE #{var :db_name}" }
end

dep 'mysql configured' do
  requires 'mysql root password'
end

dep 'mysql root password' do
  requires 'mysql software'
  met? { failable_shell("echo '\q' | mysql -u root").stderr["Access denied for user 'root'@'localhost' (using password: NO)"] }
  meet { mysql(%Q{GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '#{var :db_admin_password}'}, 'root', false) }
end

pkg 'mysql software' do
  installs {
    apt %w[mysql-server libmysqlclient15-dev]
    macports 'mysql5-server'
  }
  provides 'mysql'
  after {
    if host.osx?
      sudo "ln -s #{Babushka::MacportsHelper.prefix / 'lib/mysql5/bin/mysql*'} #{Babushka::MacportsHelper.prefix / 'bin/'}"
    end
  }
end
