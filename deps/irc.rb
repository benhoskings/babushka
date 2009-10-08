dep 'irc' do
  requires 'ngircd'
  met? { babushka_config? '/etc/ngircd/ngircd.conf' }
  before { sudo "chmod o+rx /etc/ngircd" }
  meet { render_erb 'ngircd/ngircd.conf.erb', :to => '/etc/ngircd/ngircd.conf', :sudo => true }
  after { sudo "/etc/init.d/ngircd restart" }
end

pkg 'ngircd' do
  installs { via :apt, 'ngircd' }
end
