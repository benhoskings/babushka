require 'spec_support'

def test_dep_source name = 'test'
  returning ["file:/#{tmp_prefix / 'source_remotes' / name}", {:name => name}] do |source|
    source_path = source.first.gsub(/^file:\//, '')
    unless File.exists? source_path / '.git'
      shell %Q{
        mkdir -p "#{source_path}" &&
        cd "#{source_path}" &&
        git init &&
        echo 'dep "#{name}" do end' > '#{name}.rb' &&
        git add . &&
        git commit -m "committed during test run"
      }
    end
  end
end
