dep 'vhost enabled' do
  define_var :www_aliases, :default => L{
    "#{var :domain} #{var :extra_domains}".split(' ').compact.map(&:strip).reject {|d|
      d.starts_with? '*.'
    }.reject {|d|
      d.starts_with? 'www.'
    }.map {|d|
      "www.#{d}"
    }.join(' ')
  }
  requires 'vhost configured'
  met? { File.exists? "/opt/nginx/conf/vhosts/on/#{var :domain}.conf" }
  meet { sudo "ln -sf '/opt/nginx/conf/vhosts/#{var :domain}.conf' '/opt/nginx/conf/vhosts/on/#{var :domain}.conf'" }
  after { restart_nginx }
end

dep 'vhost configured' do
  requires 'webserver configured'
  met? { File.exists? "/opt/nginx/conf/vhosts/#{var :domain}.conf" }
  meet {
    render_erb "nginx/#{var :vhost_type, :default => 'passenger'}_vhost.conf.erb",   :to => "/opt/nginx/conf/vhosts/#{var :domain}.conf", :sudo => true
    render_erb "nginx/#{var :vhost_type, :default => 'passenger'}_vhost.common.erb", :to => "/opt/nginx/conf/vhosts/#{var :domain}.common", :sudo => true, :optional => true
  }
  after { restart_nginx if File.exists? "/opt/nginx/conf/vhosts/on/#{var :domain}.conf" }
end

dep 'self signed cert' do
  requires 'webserver installed'
  met? { %w[key csr crt].all? {|ext| File.exists? "/opt/nginx/conf/certs/#{var :domain}.#{ext}" } }
  meet { generate_self_signed_cert }
end

def build_nginx opts = {}
  in_build_dir {
    get_source("http://sysoev.ru/nginx/nginx-#{opts[:nginx]}.tar.gz") and
    get_source("http://www.grid.net.ru/nginx/download/nginx_upload_module-#{opts[:upload_module]}.tar.gz") and
    log_shell("Building nginx (this takes a minute or two)", "sudo passenger-install-nginx-module", :input => [
      '', # enter to continue
      '2', # custom build
      pathify("nginx-#{opts[:nginx]}"), # path to nginx source
      '', # accept /opt/nginx target path
      "--with-http_ssl_module --add-module='#{pathify "nginx_upload_module-#{opts[:upload_module]}"}'",
      '', # confirm settings
      '', # enter to continue
      '' # done
      ].join("\n")
    )
  }
end

def generate_self_signed_cert
  in_dir "/opt/nginx/conf/certs", :create => "700", :sudo => true do
    log_shell("generating private key", "openssl genrsa -out #{var :domain}.key 1024", :sudo => true) and
    log_shell("generating certificate", "openssl req -new -key #{var :domain}.key -out #{var :domain}.csr", :sudo => true, :input => [
        var(:country, 'AU'),
        var(:state),
        var(:city, ''),
        var(:organisation),
        var(:organisational_unit, ''),
        var(:domain),
        var(:email),
        '', # password
        '', # optional company name
        '' # done
      ].join("\n")
    ) and
    log_shell("signing certificate with key", "openssl x509 -req -days 365 -in #{var :domain}.csr -signkey #{var :domain}.key -out #{var :domain}.crt", :sudo => true)
  end
end

def nginx_running?
  shell "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
end

def restart_nginx
  if nginx_running?
    log_shell "Restarting nginx", "/opt/nginx/sbin/nginx -s reload", :sudo => true
  end
end

dep 'webserver running' do
  requires 'webserver configured', 'webserver startup script'
  met? {
    returning nginx_running? do |result|
      result "There is #{result ? 'something' : 'nothing'} listening on #{result ? result.scan(/[0-9.*]+[.:]80/).first : 'port 80'}", :result => result
    end
  }
  meet {
    if linux?
      sudo '/etc/init.d/nginx start'
    elsif osx?
      log_error "launchctl should have already started nginx. Check /var/log/system.log for errors."
    end
  }
end

dep 'webserver startup script' do
  requires 'webserver installed', 'rcconf'
  met? {
    if linux?
      shell("rcconf --list").val_for('nginx') == 'on'
    elsif osx?
      sudo('launchctl list').val_for('org.nginx')
    end
  }
  meet {
    if linux?
      render_erb 'nginx/nginx.init.d.erb', :to => '/etc/init.d/nginx', :perms => '755', :sudo => true
      sudo 'update-rc.d nginx defaults'
    elsif osx?
      render_erb 'nginx/nginx.launchd.erb', :to => '/Library/LaunchDaemons/org.nginx.plist', :sudo => true
      sudo 'launchctl load -w /Library/LaunchDaemons/org.nginx.plist'
    end
  }
end

dep 'webserver configured' do
  requires 'webserver installed', 'www user and group'
  met? {
    if babushka_config? '/opt/nginx/conf/nginx.conf'
      configured_root = IO.read('/opt/nginx/conf/nginx.conf').val_for('passenger_root')
      passenger_root = Babushka::GemHelper.gem_path_for('passenger')
      returning configured_root == passenger_root do |result|
        log_result "nginx is configured to use #{File.basename configured_root}", :result => result
      end
    end
  }
  meet {
    set :passenger_root, Babushka::GemHelper.gem_path_for('passenger')
    render_erb 'nginx/nginx.conf.erb', :to => '/opt/nginx/conf/nginx.conf', :sudo => true
  }
  after {
    sudo "mkdir -p /opt/nginx/conf/vhosts/on"
    restart_nginx
  }
end

dep 'webserver installed' do
  requires 'passenger', 'build tools', 'libssl headers', 'zlib headers'
  merge :versions, {:nginx => '0.8.15', :upload_module => '2.0.9'}
  met? {
    if !File.executable?('/opt/nginx/sbin/nginx')
      unmet "nginx isn't installed"
    else
      installed_version = shell('/opt/nginx/sbin/nginx -V') {|shell| shell.stderr }.val_for('nginx version').sub('nginx/', '')
      if installed_version != versions[:nginx]
        unmet "an outdated version of nginx is installed (#{installed_version})"
      elsif !shell('/opt/nginx/sbin/nginx -V') {|shell| shell.stderr }[Babushka::GemHelper.gem_path_for('passenger')]
        unmet "nginx is installed, but built against the wrong passenger version"
      else
        met "nginx-#{installed_version} is installed"
      end
    end
  }
  meet { build_nginx versions }
end
