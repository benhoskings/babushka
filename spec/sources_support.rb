require 'spec/spec_support'

require 'rubygems'
require 'fakefs/safe'

def dep_source name = 'test'
  returning tmp_prefix / 'source_remotes' / name do |path|
    unless File.exists? path / '.git'
      shell %Q{
        mkdir -p "#{path}" &&
        cd "#{path}" &&
        git init &&
        echo 'dep "#{name}" do end' > '#{name}.rb' &&
        git add . &&
        git commit -m "committed during test run"
      }
    end
  end
end
