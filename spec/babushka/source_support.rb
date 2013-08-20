require 'spec_helper'

def make_source_remote name = 'test'
  path = tmp_prefix / 'sources' / name
  remote_path = tmp_prefix / 'source_remotes' / name
  [path, name, "file://#{remote_path}"].tap {|source|
    unless File.exists?(remote_path / '.git')
      ShellHelpers.shell %Q{
        mkdir -p "#{remote_path}" &&
        cd "#{remote_path}" &&
        git init &&
        echo 'dep "#{name}" do end' > '#{name}.rb' &&
        git add . &&
        git commit -m "committed during test run"
      }
    end
  }
end
