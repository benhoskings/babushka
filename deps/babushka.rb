dep 'babushka' do
  requires 'set up.babushka'
  setup {
    set :babushka_branch, 'master'
    set :install_path, Babushka::Path.path if Babushka::Path.run_from_path?
  }
end

dep 'babushka next' do
  requires 'set up.babushka'
  setup {
    set :babushka_branch, 'next'
    set :install_path, Babushka::Path.path if Babushka::Path.run_from_path?
  }
end

meta :babushka do
  def repo
    Babushka::GitRepo.new var(:install_path)
  end
end

dep 'set up.babushka' do
  requires 'up to date.babushka', 'in path.babushka'
  define_var :install_path, :default => '/usr/local/babushka', :message => "Where would you like babushka installed"
  define_var :babushka_branch,
    :message => "Which branch would you like to update from?",
    :default => 'master',
    :choice_descriptions => {
      'master' => 'Standard-issue babushka',
      'next' => 'The development head -- slight risk of explosions'
    }
end

dep 'up to date.babushka' do
  requires 'repo clean.babushka', 'update would fast forward.babushka'
  met? {
    (!repo.behind?).tap {|result|
      if result
        log_ok "babushka is up to date at revision #{repo.current_head}."
      else
        log "babushka can be updated: #{repo.current_head}..#{repo.repo_shell("git rev-parse --short origin/#{var(:babushka_branch)}")}"
      end
    }
  }
  meet {
    log "#{repo.repo_shell("git diff --stat #{repo.current_head}..origin/#{var(:babushka_branch)}")}"
    repo.reset_hard! "origin/#{var(:babushka_branch)}"
  }
end

dep 'update would fast forward.babushka' do
  requires 'on correct branch.babushka'
  met? {
    if !repo.repo_shell('git fetch origin')
      unmeetable "Couldn't pull the latest code - check your internet connection."
    else
      if !repo.remote_branch_exists?
        unmeetable "The current branch, #{repo.current_branch}, isn't pushed to origin/#{repo.current_branch}."
      elsif repo.ahead?
        unmeetable "There are unpushed commits in #{repo.current_branch}."
      else
        true
      end
    end
  }
end

dep 'on correct branch.babushka' do
  requires 'branch exists.babushka'
  requires_when_unmet 'repo clean.babushka'
  met? { repo.current_branch == var(:babushka_branch) }
  meet { repo.checkout! var(:babushka_branch) }
end

dep 'branch exists.babushka' do
  requires 'installed.babushka'
  met? { repo.branches.include? var(:babushka_branch) }
  meet { repo.track! "origin/#{var(:babushka_branch)}" }
end

dep 'repo clean.babushka' do
  requires 'installed.babushka'
  met? {
    repo.clean? or unmeetable("There are local changes in #{repo.path}.")
  }
end

dep 'in path.babushka' do
  requires 'installed.babushka'
  def bin_path
    repo.path / '../bin'
  end
  setup {
    unmeetable "The binary path alongside babushka, #{bin_path}, isn't in your $PATH." unless ENV['PATH'].split(':').include?(bin_path)
    unmeetable "The current user, #{shell('whoami')}, can't write to #{bin_path} (to symlink babushka into the path)." unless bin_path.hypothetically_writable?
  }
  met? { which 'babushka' }
  meet {
    bin_path.mkdir
    log_shell "Linking babushka into #{bin_path}", %Q{ln -sf "#{repo.path / 'bin/babushka.rb'}" "#{bin_path / 'babushka'}"}
  }
end

dep 'installed.babushka' do
  requires 'ruby', 'git'
  def babushka_source
    "git://github.com/benhoskings/babushka.git"
  end
  setup {
    unmeetable "The current user, #{shell('whoami')}, can't write to #{repo.path}." unless repo.path.hypothetically_writable?
  }
  met? { repo.exists? }
  meet {
    log_block "Cloning #{babushka_source} into #{repo.path}" do
      repo.clone! babushka_source
    end
  }
end
