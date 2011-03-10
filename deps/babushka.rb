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
  setup {
    raise UnmeetableDep, "The current user, #{shell('whoami')}, can't write to #{var(:install_path)}." unless var(:install_path).p.writable?
  }
end

dep 'up to date.babushka' do
  requires 'repo clean.babushka', 'update would fast forward.babushka'
  met? {
    returning !repo.behind? do |result|
      if result
        log_ok "babushka is up to date at revision #{repo.current_head}."
      else
        log "babushka can be updated: #{repo.current_head}..#{repo.repo_shell("git rev-parse --short origin/#{var(:babushka_branch)}")}"
      end
    end
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
  requires 'repo clean.babushka', 'branch exists.babushka'
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
    repo.clean? or unmeetable("There are local changes in #{var(:install_path)}.")
  }
end

dep 'in path.babushka' do
  requires 'up to date.babushka'
  met? { which 'babushka' }
  meet {
    log_shell "Linking babushka into #{var(:install_path) / '../bin'}", %Q{ln -sf "#{var(:install_path) / 'bin/babushka.rb'}" "#{var(:install_path) / '../bin/babushka'}"}
  }
end

dep 'installed.babushka' do
  requires 'ruby', 'git'
  requires_when_unmet 'writable.install_path'
  setup { set :babushka_source, "git://github.com/benhoskings/babushka.git" }
  met? { repo.exists? }
  meet { repo.clone! var(:babushka_source) }
end
