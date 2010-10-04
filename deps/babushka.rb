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
  template {
    run_in L{ var(:install_path) }
  }
end

dep 'set up.babushka' do
  requires 'up to date.babushka', 'babushka in path'
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
    returning shell("git rev-list ..origin/#{var :babushka_branch}").split("\n").empty? do |result|
      if result
        log_ok "babushka is up to date at revision #{shell('git rev-parse --short HEAD')}."
      else
        log "babushka can be updated: #{shell('git rev-parse --short HEAD')}..#{shell("git rev-parse --short origin/#{var(:babushka_branch)}")}"
      end
    end
  }
  meet { shell("git reset --hard origin/#{var :babushka_branch}", :log => true) }
end

dep 'update would fast forward.babushka' do
  requires 'on correct branch.babushka'
  met? {
    if !shell('git fetch origin')
      fail_because("Couldn't pull the latest code - check your internet connection.")
    else
      current_branch = shell("git branch").split("\n").collapse(/^\* /).first
      if !shell('git branch -a').split("\n").map(&:strip).detect {|b| b[/^(remotes\/)?origin\/#{current_branch}$/] }
        fail_because("The current branch, #{current_branch}, isn't pushed to origin/#{current_branch}.")
      elsif !shell("git rev-list origin/#{current_branch}..").split("\n").empty?
        fail_because("There are unpushed commits in #{current_branch}.")
      else
        true
      end
    end
  }
end

dep 'on correct branch.babushka' do
  requires 'repo clean.babushka', 'branch exists.babushka'
  met? { shell("git branch").split("\n").collapse(/^\* /).first == var(:babushka_branch) }
  meet { shell("git checkout '#{var(:babushka_branch)}'") }
end

dep 'branch exists.babushka' do
  requires 'babushka installed'
  met? { !shell("git branch").split("\n").map {|i| i.gsub(/^[* ]+/, '') }.grep(var(:babushka_branch)).empty? }
  meet { shell("git checkout -t 'origin/#{var(:babushka_branch)}'") }
end

dep 'repo clean.babushka' do
  requires 'babushka installed'
  met? {
    shell('git ls-files -m').split("\n").empty? or
    fail_because("There are local changes in #{var(:install_path)}.")
  }
end

dep 'babushka in path' do
  requires 'up to date.babushka'
  met? { which 'babushka' }
  meet {
    log_shell "Linking babushka into #{var(:install_path) / '../bin'}", %Q{ln -sf "#{var(:install_path) / 'bin/babushka.rb'}" "#{var(:install_path) / '../bin/babushka'}"}
  }
end

dep 'babushka installed' do
  requires 'ruby', 'git'
  requires_when_unmet 'writable.install_path'
  setup { set :babushka_source, "git://github.com/benhoskings/babushka.git" }
  met? { git_repo?(var(:install_path)) }
  meet {
    in_dir var(:install_path).p.parent do |path|
      log_shell "Installing babushka to #{var(:install_path)}", %Q{git clone "#{var :babushka_source}" "#{var(:install_path).p.basename}"}
    end
  }
end
