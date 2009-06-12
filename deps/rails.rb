dep 'migrated db' do
  requires 'db access', 'rails'
  met? {
    current_version = rake("db:version").val_for('Current version')
    latest_version = Dir.glob('db/migrate').push('0').sort.last.split('_', 2).first
    returning current_version == latest_version do |result|
      if result
        log "DB is up to date at migration #{current_version}"
      else
        log "DB needs migrating from #{current_version} to #{latest_version}"
      end
    end
  }
  meet { rake("db:migrate --trace") }
end

gem_dep 'rails' do
  requires 'rubygems'
  pkg 'rails'
  provides 'rails'
end
