dep 'system' do
  requires 'hostname', 'correct path', 'secured ssh logins', 'lax host key checking', 'admins can sudo'
  run_as 'root'
end

dep 'user setup' do
  requires 'user shell setup', 'passwordless ssh logins', 'public key', 'vim'
  run_as :username
end

dep 'rails app' do
  requires 'gems installed', 'vhost enabled', 'webserver running', 'migrated db'
  run_as :username
  asks_for :domain, :rails_env
end
