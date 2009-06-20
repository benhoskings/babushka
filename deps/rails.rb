dep 'migrated db' do
  requires 'db access', 'rails'
  met? {
    current_version = rake("db:version") {|shell| shell.stdout.val_for('Current version') }
    latest_version = Dir.glob('db/migrate').push('0').sort.last.split('_', 2).first
    returning current_version == latest_version do |result|
      if latest_version == '0'
        log_verbose "This app doesn't have any migrations yet."
      elsif result
        log_ok "DB is up to date at migration #{current_version}"
      else
        log "DB needs migrating from #{current_version} to #{latest_version}"
      end
    end
  }
  meet { rake("db:migrate --trace") }
end

dep 'existing db' do
  requires 'db gem', 'rails'
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*testapp\s+\|/)
    }.empty?
  }
  meet { rake("db:create") }
end

gem_dep 'rails' do
  requires 'rubygems'
end
