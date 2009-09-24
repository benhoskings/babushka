dep 'system' do
  requires 'hostname', 'secured ssh logins', 'lax host key checking', 'admins can sudo', 'tmp cleaning grace period', 'core software'
end

dep 'user setup' do
  requires 'user shell setup', 'passwordless ssh logins', 'public key'
  define_var :username, :default => shell('whoami')
  setup {
    set :username, shell('whoami')
    set :home_dir_base, "/home"
  }
end

dep 'rails app' do
  requires 'webapp', 'passenger deploy repo', 'gems installed', 'migrated db'
  define_var :rails_env, :default => 'production'
  define_var :rails_root, :default => '~/current'
  setup {
    set :vhost_type, 'passenger'
    set :db_name, yaml(var(:rails_root) / 'config/database.yml')[var(:rails_env)]['database']
  }
end

dep 'proxied app' do
  requires 'webapp'
  setup {
    set :vhost_type, 'proxy'
  }
end

dep 'webapp' do
  requires 'user exists', 'vhost enabled', 'webserver running'
  define_var :domain, :default => :username
  setup {
    set :home_dir_base, "/srv/http"
  }
end

dep 'core software' do
  requires 'fish', 'vim', 'curl', 'htop', 'jnettop', 'screen', 'nmap'
end
