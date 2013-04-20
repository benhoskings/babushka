meta :babushka do
  def repo
    Babushka::GitRepo.new(path)
  end

  def qualified_ref
    # Prepend "origin/" we're installing from scratch, or if the result is a
    # valid remote branch.
    if repo.exists? && repo.all_branches.include?("origin/#{ref}")
      "origin/#{ref}"
    else
      ref
    end
  end

  def resolved_ref
    repo.resolve(qualified_ref)
  end
end

dep 'babushka', :from, :path, :version do
  version.default!('stable')
  requires 'up to date.babushka'.with(from, path, version)
  requires 'in path.babushka'.with(from, path)
  path.ask("Where would you like babushka installed").default('/usr/local/babushka')
  path.default!(Babushka::Path.path) if Babushka::Path.run_from_path?
end

dep 'up to date.babushka', :from, :path, :ref do
  requires 'repo clean.babushka'.with(from, path)
  requires 'resolvable ref.babushka'.with(from, path, ref)

  met? {
    (repo.current_head == resolved_ref).tap {|result|
      if result
        log_ok "babushka is up to date at #{repo.current_head}."
      else
        log "babushka can be updated: #{repo.current_head}..#{resolved_ref}"
      end
    }
  }
  meet {
    log "#{repo.repo_shell("git diff --stat #{repo.current_head}..#{resolved_ref}")}"
    repo.detach!(resolved_ref)
  }
end

dep 'repo clean.babushka', :from, :path do
  requires 'installed.babushka'.with(from, path)
  met? {
    repo.clean? or unmeetable!("There are local changes in #{repo.path}.")
  }
end

dep 'resolvable ref.babushka', :from, :path, :ref do
  met? {
    if !@fetched && qualified_ref['origin/']
      log "Need to fetch before resolving #{qualified_ref}."
    else
      resolved_ref.tap {|result|
        if result == qualified_ref
          log_ok "#{result} is already resolved."
        elsif result
          log_ok "#{ref} resolves to #{result}."
        else
          log "#{ref} doesn't resolve to a ref."
        end
      }
    end
  }
  meet {
    log_block "Fetching #{from}", :failure => "failed, check your internet connection." do
      @fetched = true
      repo.repo_shell?('git fetch origin')
    end
  }
end

dep 'in path.babushka', :from, :path do
  requires 'installed.babushka'.with(from, path)
  def bin_path
    repo.path / '../bin'
  end
  setup {
    unless ENV['PATH'].split(':').map {|p| p.chomp('/') }.include?(bin_path)
      unmeetable! "The binary path alongside babushka, #{bin_path}, isn't in your $PATH."
    end
  }
  met? { which 'babushka' }
  prepare {
    unmeetable! "The current user, #{shell('whoami')}, can't write to #{bin_path} (to symlink babushka into the path)." unless bin_path.hypothetically_writable?
  }
  meet {
    bin_path.mkdir
    log_shell "Linking babushka into #{bin_path}", %Q{ln -sf "#{repo.path / 'bin/babushka.rb'}" "#{bin_path / 'babushka'}"}
  }
end

dep 'installed.babushka', :from, :path do
  from.default!("https://github.com/benhoskings/babushka.git")

  requires 'ruby', 'git'
  setup {
    unmeetable! "The current user, #{shell('whoami')}, can't write to #{repo.path}." unless repo.path.hypothetically_writable?
  }
  met? { repo.exists? }
  meet {
    log_block "Cloning #{from} into #{repo.path}" do
      repo.clone! from
    end
  }
end
