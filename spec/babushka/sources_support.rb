require 'spec_support'

def dep_source name = 'test'
  returning :name => name, :uri => tmp_prefix / 'source_remotes' / name do |source|
    unless File.exists? source[:uri] / '.git'
      shell %Q{
        mkdir -p "#{source[:uri]}" &&
        cd "#{source[:uri]}" &&
        git init &&
        echo 'dep "#{name}" do end' > '#{name}.rb' &&
        git add . &&
        git commit -m "committed during test run"
      }
    end
  end
end
