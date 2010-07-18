dep 'babushka' do
  requires 'set up.babushka'
  setup { set :babushka_branch, 'master' }
end

dep 'babushka next' do
  requires 'set up.babushka'
  setup { set :babushka_branch, 'next' }
end

meta :babushka do
  template {
    run_in L{ var(:install_path) }
  }
end

dep 'set up.babushka' do
  requires 'babushka in path', 'up to date.babushka'
  define_var :install_path, :default => '/usr/local/babushka', :message => "Where would you like babushka installed"
  define_var :babushka_branch,
    :message => "Which branch would you like to update from?",
    :default => 'master',
    :choice_descriptions => {
      'master' => 'Standard-issue babushka',
      'next' => 'The development head -- slight risk of explosions'
    }
  setup {
    set :install_path, Babushka::Path.path if Babushka::Path.run_from_path?
  }
end

dep 'up to date.babushka' do
  requires 'repo clean.babushka', 'update would fast forward.babushka'
  met? {
    in_dir(var(:install_path)) {
      shell("git rev-list ..origin/#{var :babushka_branch}").split("\n").empty?
    }
  }
  meet { in_dir(var(:install_path)) { shell("git merge origin/#{var :babushka_branch}", :log => true) } }
end

dep 'update would fast forward.babushka' do
  requires 'babushka installed'
  met? {
    in_dir(var(:install_path)) {
      if !shell('git fetch')
        fail_because("Couldn't pull the latest code - check your internet connection.")
      else
        current_branch = shell("git branch").split("\n").collapse(/^\* /).first
        shell("git rev-list origin/#{current_branch}..").split("\n").empty? or
        fail_because("There are unpushed commits in #{current_branch}.")
      end
    }
  }
end

dep 'repo clean.babushka' do
  requires 'babushka installed'
  met? {
    in_dir(var(:install_path)) {
      shell('git ls-files -m').split("\n").empty? or
      fail_because("There are local changes in #{var(:install_path)}.")
    }
  }
end

dep 'babushka in path' do
  requires 'babushka installed'
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
