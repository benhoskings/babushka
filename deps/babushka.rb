meta :babushka do
  def repo
    Babushka::GitRepo.new(path)
  end
end

dep 'babushka', :from, :path, :version, :branch do
  ref = if branch.set?
    deprecated! '2012-12-20', :method_name => "the :branch parameter to 'babushka'", :instead => ':version'
    branch
  else
    version.default!('master')
  end
  requires 'up to date.babushka'.with(from, path, ref)
  requires 'in path.babushka'.with(from, path)
  path.ask("Where would you like babushka installed").default('/usr/local/babushka')
  path.default!(Babushka::Path.path) if Babushka::Path.run_from_path?
end

dep 'up to date.babushka', :from, :path, :ref do
  def qualified_ref
    # Prepend "origin/" if the result is a valid remote branch.
    if repo.all_branches.include?("origin/#{ref}")
      "origin/#{ref}"
    else
      ref
    end
  end

  def refspec
    repo.resolve(qualified_ref)
  end

  requires 'repo clean.babushka'.with(from, path)
  requires 'resolvable ref.babushka'.with(from, path, qualified_ref)

  met? {
    (repo.current_head == refspec).tap {|result|
      if result
        log_ok "babushka is up to date at #{repo.current_head}."
      else
        log "babushka can be updated: #{repo.current_head}..#{refspec}"
      end
    }
  }
  meet {
    log "#{repo.repo_shell("git diff --stat #{repo.current_head}..#{refspec}")}"
    repo.detach!(refspec)
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
    if !@fetched && ref['origin/']
      false # Always fetch before resolving a remote ref.
    else
      repo.resolve(ref).tap {|result|
        if result
          log_ok "#{ref} resolves to #{result}."
        else
          log "#{ref} doesn't resolve to a ref."
        end
      }
    end
  }
  meet {
    result = log_block "Fetching #{from}", :failure => "failed, check your internet connection." do
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
