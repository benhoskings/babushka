dep 'system' do
  requires 'hostname', 'secured ssh logins', 'lax host key checking', 'admins can sudo', 'core software'
end

dep 'user setup' do
  requires 'user shell setup', 'passwordless ssh logins', 'public key'
  define_var :username, :default => shell('whoami')
  set :home_dir_base, "/home"
end

dep 'rails app' do
  requires 'user setup', 'deploy repo', 'gems installed', 'vhost enabled', 'webserver running', 'migrated db'
  define_var :domain, :default => :username
  define_var :rails_env, :default => 'production'
  define_var :rails_root, :default => '~/current'
  set :home_dir_base, "/srv/http"
end

dep 'core software' do
  requires 'fish', 'vim', 'curl', 'mdns', 'htop', 'jnettop', 'screen'
end
