dep 'homebrew binary in place' do
  requires 'homebrew installed'
  met? { which 'brew' }
  meet {
    in_dir var :install_prefix do
      log_shell "Resetting to HEAD", "git reset --hard"
    end
  }
end

dep 'homebrew installed' do
  requires_when_unmet 'writable install location', 'git'
  define_var :homebrew_repo_user, :default => 'mxcl', :message => "Whose homebrew repo would you like to use?"
  setup {
    if Babushka::BrewHelper.present?
      set :install_prefix, Babushka::BrewHelper.prefix # Use the existing homebrew install if there is one
    end
  }
  met? { File.exists? var(:install_prefix) / '.git' }
  meet {
    git "git://github.com/#{var :homebrew_repo_user}/homebrew.git" do |path|
      log_shell "Gitifying #{var :install_prefix}", "cp -r .git '#{var :install_prefix}'"
    end
  }
end
