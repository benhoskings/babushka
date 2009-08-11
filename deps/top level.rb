dep 'system' do
  requires 'hostname', 'correct path', 'secured ssh logins', 'lax host key checking', 'admins can sudo'
end

dep 'user setup' do
  requires 'user shell setup', 'passwordless ssh logins', 'public key', 'vim'
  define_var :username, :default => shell('whoami')
end

dep 'rails app' do
  requires 'gems installed', 'vhost enabled', 'webserver running', 'migrated db'
  define_var :domain, :default => :username
  define_var :rails_env, :default => 'production'
  define_var :rails_root, :default => '~/current'
end
