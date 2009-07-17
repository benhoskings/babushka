dep 'rails app' do
  requires 'gems installed', 'vhost enabled', 'webserver running', 'migrated db'
  asks_for :domain, :username, :rails_env
end

def parse_config_gem_deps
  IO.readlines(
    File.expand_path rails_root / 'config/environment.rb'
  ).grep(/^\s*config\.gem/).map {|l|
    i = l.scan /config\.gem[\s\('"]+([\w-]+)(['"],\s*\:version\s*=>\s*['"]([<>=!~.0-9\s]+)['"])?.*$/

    if i.first.nil? || i.first.first.nil?
      log_error "Couldn't parse '#{l.chomp}' in #{File.expand_path 'config/environment.rb'}."
    else
      ver i.first.first, i.first.last
    end
  }.compact
end

def parse_rails_dep
  IO.readlines(
    File.expand_path rails_root / 'config/environment.rb'
  ).grep(/RAILS_GEM_VERSION/).map {|l|
    $1 if l =~ /^[^#]*RAILS_GEM_VERSION\s*=\s*["']([!~<>=]*\s*[\d.]+)["']/
  }.compact
end

def parse_gem_deps
  parse_config_gem_deps + parse_rails_dep
end

dep 'gems installed' do
  setup {
    parse_gem_deps.map {|gem_spec|
      # Make a new Dep for each gem this app needs...
      gem("#{gem_spec.name} gem") {
        installs gem_spec
        provides []
      }
    }.each {|dep|
      # ... and set each one as a requirement of this dep.
      requires dep.name
    }
  }
end

dep 'migrated db' do
  requires 'deployed app', 'existing db', 'rails'
  met? {
    current_version = rails_rake("db:version") {|shell| shell.stdout.val_for('Current version') }
    latest_version = Dir.glob('db/migrate').push('0').sort.last.split('_', 2).first
    returning current_version == latest_version do |result|
      unless current_version.blank?
        if latest_version == '0'
          log_verbose "This app doesn't have any migrations yet."
        elsif result
          log_ok "DB is up to date at migration #{current_version}"
        else
          log "DB needs migrating from #{current_version} to #{latest_version}"
        end
      end
    end
  }
  meet { rails_rake "db:migrate --trace" }
end

dep 'deployed app' do
  met? { File.directory? File.expand_path rails_root / 'app' }
end

dep 'existing db' do
  requires 'db gem', 'db access', 'db backups', 'rails'
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{db_name username}\s+\|/)
    }.empty?
  }
  meet { rails_rake "db:create" }
end

gem 'rails'
