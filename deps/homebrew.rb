
dep 'homebrew' do
  requires 'homebrew installed'
  met? { which 'brew' }
  meet {
    in_dir var :install_prefix do
      log_shell "Resetting to HEAD", "git reset --hard"
    end
  }
end

dep 'homebrew installed' do
  define_var :homebrew_repo_user, :default => 'mxcl', :message => "Whose homebrew repo would you like to install from?"
  setup {
    if Babushka::BrewHelper.present?
      # There's some homebrew install already - no extra git/brew checks needed.
      set :install_prefix, Babushka::BrewHelper.prefix
    elsif which 'git'
      # We have git but not brew - prepare for initial brew install
      definer.requires 'writable install location'
    else
      # We have neither git nor brew - install git via brew bootstrap
      definer.requires 'homebrew git'
    end
  }
  met? { File.exists? var(:install_prefix) / '.git' }
  meet {
    git "git://github.com/#{var :homebrew_repo_user}/homebrew.git" do |path|
      log_shell "Gitifying #{var :install_prefix}", "cp -r .git '#{var :install_prefix}'"
    end
  }
end

pkg 'homebrew git' do
  requires 'homebrew bootstrap'
  setup { definer.requires.delete 'homebrew' }
  installs { via :brew, 'git' }
  provides 'git'
end

dep 'homebrew bootstrap' do
  requires 'writable install location'
  met? { cmds_in_path? 'brew' }
  meet {
    source "http://github.com/#{var :homebrew_repo_user}/homebrew/tarball/masterbrew", 'masterbrew.tgz' do |path|
      log "Installing temporary homebrew to #{var :install_prefix}."
      FileUtils.cp_r 'bin/brew', var(:install_prefix) / 'bin'
      File.chmod 0755, var(:install_prefix) / 'bin/brew'
      FileUtils.cp_r 'Library', var(:install_prefix)
    end
  }
end
