dep 'release', :version do
  requires [
    'release on origin'.with(version)
  ]
end

dep 'release on origin', :version do
  def repo
    Babushka::GitRepo.new('.')
  end
  def release_tag
    version.to_s.sub(/^(?!v)/, 'v')
  end
  requires [
    'release exists'.with(:version => version)
  ]
  met? {
    shell?("git ls-remote --tags origin").split("\n").grep(%r{refs/tags/#{release_tag}$}).any?
  }
  meet {
    log_shell "Pushing #{release_tag} to origin", 'git push origin'
    log_shell "Pushing tags to origin", 'git push origin --tags'
  }
end

dep 'release exists', :version, :version_file do
  version_file.default!('./lib/babushka.rb')
  def repo
    Babushka::GitRepo.new('.')
  end
  def release_tag
    version.to_s.sub(/^(?!v)/, 'v')
  end
  def update_version!
    sed_expression = "s/^(  *VERSION  *= ).*$/\\1'#{version}'/"
    shell! 'sed', '-i.bak', '-r', sed_expression, version_file
    shell! 'rm', "#{version_file}.bak"
  end
  def git_log from, to
    log shell("git log --graph --date-order --pretty='format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset' #{from}..#{to}")
  end
  def most_recent_version
    shell('git tag').split("\n").map {|t| Babushka::VersionStr.new(t) }.max
  end
  requires [
    'repo on master'
  ]
  requires_when_unmet [
    'repo clean',
    'build passing',
  ]
  met? {
    repo.resolve(release_tag)
  }
  meet {
    git_log "v#{most_recent_version}", 'HEAD'
    confirm "Create #{release_tag} from this changeset?" do
      log_block("Writing version to #{version_file}") { update_version! }
      log_shell "Committing", "git commit #{version_file} --message '#{release_tag} - ' --edit"
      log_shell "Tagging", "git tag '#{release_tag}'"
    end
  }
end

dep 'repo on master' do
  def repo
    Babushka::GitRepo.new('.')
  end
  met? {
    repo.current_branch == 'master' || unmeetable!("Releases have to be made from master.")
  }
end

dep 'repo clean' do
  def repo
    Babushka::GitRepo.new('.')
  end
  setup {
    repo.repo_shell "git diff" # Clear git's internal cache, which sometimes says the repo is dirty when it isn't.
  }
  met? { repo.clean? || unmeetable!("The remote repo has local changes.") }
end

dep 'build passing' do
  met? {
    log_shell("Running specs", "bundle exec rspec --format documentation") || unmeetable!("Can't make a release when the build is broken.")
  }
end
