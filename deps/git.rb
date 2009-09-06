dep 'deploy repo' do
  requires 'git', 'user exists'
  met? { File.directory? pathify var(:rails_root) / '.git' }
  meet {
    FileUtils.mkdir_p pathify var(:rails_root) and
    in_dir var(:rails_root) do
      shell "git init"
      shell "echo 'cd ..; env -i git reset --hard' > #{pathify var(:rails_root) / '.git/hooks/post-receive'}"
      shell "chmod +x #{pathify var(:rails_root) / '.git/hooks/post-receive'}"
    end
  }
end
