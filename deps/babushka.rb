
dep 'babushka' do
  requires 'babushka in path', 'babushka up to date', 'dep source'
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
    set :babushka_branch, 'master'
  }
end

dep 'babushka up to date' do
  requires 'babushka repo clean', 'babushka update would fast forward'
  met? {
    in_dir(var(:install_path)) {
      shell("git rev-list ..origin/#{var :babushka_branch}").lines.to_a.empty?
    }
  }
  meet { in_dir(var(:install_path)) { shell("git merge origin/#{var :babushka_branch}", :log => true) } }
end

dep 'babushka update would fast forward' do
  requires 'babushka installed'
  met? {
    in_dir(var(:install_path)) {
      if !shell('git fetch')
        fail_because("Couldn't pull the latest code - check your internet connection.")
      else
        shell("git rev-list origin/#{var :babushka_branch}..").lines.to_a.empty? or
        fail_because("There are unpushed commits in #{var(:install_path)}.")
      end
    }
  }
end

dep 'babushka repo clean' do
  requires 'babushka installed'
  met? {
    in_dir(var(:install_path)) {
      shell('git ls-files -m').lines.to_a.empty? or
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

dep 'dep source' do
  requires 'babushka in path'
  setup {
    define_var :dep_source, :default => (shell('git config github.user') || 'benhoskings'), :message => "Whose deps would you like to install (you can add others' later)"
  }
  met? {
    returning(!(source_count = shell('babushka sources -l').split("\n").reject {|l| l.starts_with? '#' }.length).zero?) do |result|
      log_ok "There #{source_count == 1 ? 'is' : 'are'} #{source_count} dep source#{'s' unless source_count == 1} set up." if result
    end
  }
  meet { shell "babushka sources -a '#{var :dep_source}' 'git://github.com/#{var(:dep_source)}/babushka-deps'", :log => true }
end

dep 'babushka installed' do
  requires 'ruby', 'git'
  requires_when_unmet 'writable install location'
  setup { set :babushka_source, "git://github.com/benhoskings/babushka.git" }
  met? { git_repo?(var(:install_path)) }
  meet {
    in_dir var(:install_path).p.parent do |path|
      log_shell "Installing babushka to #{var(:install_path)}", %Q{git clone "#{var :babushka_source}" "#{var(:install_path).p.basename}"}
    end
  }
end
