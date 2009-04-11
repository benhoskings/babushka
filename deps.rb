require 'fakeistrano'

dep 'migrated db' do
  requires 'db access', 'existing db'
  met? { shell "rake db:version".val_for('Current version') == Dir.glob('db/migrate').sort.last.split('_', 2).first }
  meet { rake "db:migrate --trace" }
end

dep 'existing db' do
  requires 'db gem', 'db access'
  met? { shell("rake db:create")['already exists'] }
  meet { rake "db:create" }
end

gem_dep 'db gem' do
  requires 'db software'
  pkg 'pg'
  # gem_dep({
  #   'mysql' => 'mysql',
  #   'postgresql' => 'pg',
  #   'sqlite3' => 'sqlite3'
  # }[yaml('config/database.yml')[RAILS_ENV]['adapter']])
end

dep 'db access' do
  requires 'db software'
  met? { shell "echo '\\d' | psql #{dbname}" }
  meet { sudo "createuser #{appname}" }
end

pkg_dep 'db software' do
  pkg :macports => 'postgresql83-server', :apt => 'postgresql-8.2'
  provides 'psql'
  # provides({
  #   'mysql' => AptPkg.new('mysql-server', 'mysql5'),
  #   'postgresql' => AptPkg.new('postgresql-8.2', 'psql'),
  #   'sqlite3' => 'sqlite3'
  # }[yaml('config/database.yml')[RAILS_ENV]['adapter']])
end
