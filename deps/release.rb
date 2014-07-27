meta :release do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def release_tag
    version.to_s.sub(/^(?!v)/, 'v')
  end
  def git_log from, to
    log shell("git log --graph --date-order --pretty='format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset' #{from}..#{to}")
  end
  def latest_tag
    version = shell('git tag').lines.map(&:to_version).max
    "v#{version}"
  end
end

dep 'release', :version, :version_file, :template => 'release' do
  requires 'release exists'.with(version, version_file)
  setup {
    if latest_tag > release_tag
      log_warn "There is already a newer release than #{release_tag} (#{latest_tag})."
    end
  }
  met? {
    shell("git ls-remote --tags origin").split("\n").grep(%r{refs/tags/#{release_tag}$}).any?
  }
  meet {
    log_block "Pushing #{release_tag} to origin" do
      shell! 'git push origin'
      shell! 'git push origin --tags'
    end
  }
end

# This is the messy one.
dep 'release exists', :version, :version_file, :template => 'release' do
  version_file.default!('./lib/babushka.rb')

  def update_version!
    sed_expression = %q{s/^( +VERSION += +).*/\1'%s'/} % version
    shell! 'sed', '-i.bak', '-E', sed_expression, version_file
    shell! 'rm', "#{version_file}.bak"
  end

  requires 'repo on stable'
  requires_when_unmet 'repo clean', 'descendant of last release', 'build passing'

  met? {
    repo.resolve(release_tag)
  }
  meet {
    git_log "#{latest_tag}", 'HEAD'
    confirm "Create #{release_tag} from #{latest_tag} + this changeset?" do
      log_block("Writing version to #{version_file}") { update_version! }
      log_shell "Committing", "git commit #{version_file} --message '#{release_tag} - ' --edit"
      log_shell "Tagging", "git tag '#{release_tag}'"
    end
  }
end

dep 'repo on stable', :template => 'release' do
  met? {
    repo.current_branch == 'stable' || unmeetable!("Releases have to be made from stable.")
  }
end

dep 'repo clean', :template => 'release' do
  met? {
    repo.repo_shell("git diff") # Clear git's internal cache, which sometimes says the repo is dirty when it isn't.
    repo.clean? || unmeetable!("The repo has uncommitted changes.")
  }
end

dep 'build passing' do
  met? {
    log_shell("Running specs", "bundle exec rspec --format documentation") ||
      unmeetable!("Can't make a release when the build is broken.")
  }
end

dep 'descendant of last release', :template => 'release' do
  met? {
    if shell?("git rev-list HEAD | grep #{repo.resolve(latest_tag)}")
      log_ok "The most recent version (#{latest_tag} / #{repo.resolve(latest_tag)}) is a parent of HEAD."
    else
      unmeetable!("The most recent version (#{latest_tag} / #{repo.resolve(latest_tag)}) isn't a parent of HEAD.")
    end
  }
end
