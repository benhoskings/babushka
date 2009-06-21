gem_dep 'db gem' do
  requires 'db software', 'rubygems'
  pkg 'pg'
  provides []
end

dep 'db access' do
  requires 'db software', 'user exists'
  met? { sudo "echo '\\du' | psql", :as => 'postgres' }
  meet { sudo "createuser -SdR #{username}", :as => 'postgres' }
end

pkg_dep 'db software' do
  pkg :macports => 'postgresql83-server', :apt => %w[postgresql postgresql-client libpq-dev]
  provides 'psql'
end
