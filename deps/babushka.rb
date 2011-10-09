meta :babushka do
  def repo
    Babushka::GitRepo.new(path)
  end
end

dep 'babushka', :path, :source, :branch do
  requires 'up to date.babushka'.with(path, source, branch)
  requires 'in path.babushka'.with(path, source)
  path.ask("Where would you like babushka installed").default('/usr/local/babushka')
  path.default!(Babushka::Path.path) if Babushka::Path.run_from_path?
  source.default!('git://github.com/benhoskings/babushka.git')
  branch.default!('master')
end

dep 'up to date.babushka', :path, :source, :branch do
  requires 'repo clean.babushka'.with(path, source)
  requires 'update would fast forward.babushka'.with(path, branch)
  met? {
    (!repo.behind?).tap {|result|
      if result
        log_ok "babushka is up to date at revision #{repo.current_head}."
      else
        log "babushka can be updated: #{repo.current_head}..#{repo.repo_shell("git rev-parse --short origin/#{branch}")}"
      end
    }
  }
  meet {
    log "#{repo.repo_shell("git diff --stat #{repo.current_head}..origin/#{branch}")}"
    repo.reset_hard! "origin/#{branch}"
  }
end

dep 'update would fast forward.babushka', :path, :branch do
  requires 'on correct branch.babushka'.with(path, branch)
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

dep 'on correct branch.babushka', :path, :branch do
  requires 'branch exists.babushka'.with(path, branch)
  requires_when_unmet 'repo clean.babushka'
  met? { repo.current_branch == branch.to_s }
  meet { repo.checkout! branch }
end

dep 'branch exists.babushka', :path, :branch do
  requires 'installed.babushka'
  met? { repo.branches.include? branch.to_s }
  meet { repo.track! "origin/#{branch}" }
end

dep 'repo clean.babushka', :path, :source do
  requires 'installed.babushka'.with(path, source)
  met? {
    repo.clean? or unmeetable("There are local changes in #{repo.path}.")
  }
end

dep 'in path.babushka', :path, :source do
  requires 'installed.babushka'.with(path, source)
  def bin_path
    repo.path / '../bin'
  end
  setup {
    unmeetable "The binary path alongside babushka, #{bin_path}, isn't in your $PATH." unless ENV['PATH'].split(':').include?(bin_path)
  }
  met? { which 'babushka' }
  prepare {
    unmeetable "The current user, #{shell('whoami')}, can't write to #{bin_path} (to symlink babushka into the path)." unless bin_path.hypothetically_writable?
  }
  meet {
    bin_path.mkdir
    log_shell "Linking babushka into #{bin_path}", %Q{ln -sf "#{repo.path / 'bin/babushka.rb'}" "#{bin_path / 'babushka'}"}
  }
end

dep 'installed.babushka', :path, :source do
  requires 'ruby', 'git'
  setup {
    unmeetable "The current user, #{shell('whoami')}, can't write to #{repo.path}." unless repo.path.hypothetically_writable?
  }
  met? { repo.exists? }
  meet {
    log_block "Cloning #{source} into #{repo.path}" do
      repo.clone! source
    end
  }
end

