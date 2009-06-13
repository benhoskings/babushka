dep 'existing db' do
  requires 'db gem', 'rails'
  met? { !shell("psql -l").split("\n").grep(/^\s*testapp\s+\|/).empty? }
  meet { rake("db:create") }
end

gem_dep 'db gem' do
  requires 'db software', 'rubygems'
  pkg 'pg'
  provides []
end

dep 'db access' do
  requires 'existing db'
  met? { shell "echo '\\d' | psql #{dbname}" }
  meet { sudo "createuser -SDR #{appname}" }
end

pkg_dep 'db software' do
  pkg :macports => 'postgresql83-server', :apt => %w[postgresql postgresql-client libpq-dev]
  provides 'psql'
end
