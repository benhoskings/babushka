gem 'mysql gem' do
  requires 'mysql software'
  installs 'mysql'
  provides []
end

dep 'mysql access' do
  requires 'mysql db exists', 'user exists'
  define_var :db_user, :default => :username
  define_var :db_host, :default => 'localhost'
  met? { mysql "use #{var(:db_name)}" }
  meet { mysql %Q{GRANT ALL PRIVILEGES ON #{var :db_name}.* TO '#{var :db_user}'@'#{var :db_host}' IDENTIFIED BY '#{var :db_password}'} }
end

dep 'mysql db exists' do
  requires 'mysql software'
  met? { mysql("SHOW DATABASES").split("\n")[3..-1].any? {|l| /\b#{var :db_name}\b/ =~ l } }
  meet { mysql "CREATE DATABASE #{var :db_name}" }
end

pkg 'mysql software' do
  installs {
    apt %w[mysql-server libmysqlclient15-dev]
    macports 'mysql5-server'
  }
  provides 'mysql'
  after {
    if osx?
      sudo "ln -s #{Babushka::MacportsHelper.prefix / 'lib/mysql5/bin/mysql*'} #{Babushka::MacportsHelper.prefix / 'bin/'}"
    end
  }
end
