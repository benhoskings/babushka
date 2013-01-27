require 'spec_helper'

def make_source_remote name = 'test'
  ["file://#{tmp_prefix / 'source_remotes' / name}", name].tap {|source|
    source_path = source.first.gsub(/^file:\/\//, '')
    unless File.exists? source_path / '.git'
      ShellHelpers.shell %Q{
        mkdir -p "#{source_path}" &&
        cd "#{source_path}" &&
        git init &&
        echo 'dep "#{name}" do end' > '#{name}.rb' &&
        git add . &&
        git commit -m "committed during test run"
      }
    end
  }
end
