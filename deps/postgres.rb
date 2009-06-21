gem_dep 'db gem' do
  requires 'db software', 'rubygems'
  pkg 'pg'
  provides []
end

dep 'db access' do
  requires 'db software'
  met? { shell "echo '\\d' | psql #{app_name}" }
  meet { sudo "createuser -SDR #{app_name}" }
end

pkg_dep 'db software' do
  pkg :macports => 'postgresql83-server', :apt => %w[postgresql postgresql-client libpq-dev]
  provides 'psql'
end
