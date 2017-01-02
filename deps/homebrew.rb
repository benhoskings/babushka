meta :homebrew do
  def path
    Babushka::BrewHelper.present? ? Babushka::BrewHelper.prefix : '/usr/local'
  end
  def repo
    Babushka::GitRepo.new path
  end
end

dep 'binary.homebrew' do
  met? {
    in_path? 'brew'
  }
  meet {
    log_shell \
      'Installing Homebrew',
      'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
  }
end
