dep 'passenger deploy repo' do
  requires 'git', 'user exists'
  define_var :passenger_repo_root, :default => :rails_root
  met? { File.directory? pathify var(:passenger_repo_root) / '.git' }
  meet {
    FileUtils.mkdir_p pathify var(:passenger_repo_root) and
    in_dir var(:passenger_repo_root) do
      shell "git init"
      render_erb "git/deploy-repo-post-receive", :to => pathify(var(:passenger_repo_root) / '.git/hooks/post-receive')
      shell "chmod +x #{pathify var(:passenger_repo_root) / '.git/hooks/post-receive'}"
    end
  }
end
