dep 'migrated db' do
  requires 'existing db', 'rails'
  run_in :rails_root
  asks_for :rails_env
  met? {
    current_version = rake("db:version") {|shell| shell.stdout.val_for('Current version') }
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
  meet { rake("db:migrate --trace") }
end

dep 'existing db' do
  requires 'db gem', 'db access', 'rails'
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{username}\s+\|/)
    }.empty?
  }
  meet { rake("db:create") }
end

gem_dep 'rails' do
  requires 'rubygems'
end
