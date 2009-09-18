dep 'samba' do
  requires 'samba installed'
  met? { babushka_config? "/etc/samba/smb.conf" }
  meet { render_erb "samba/smb.conf.erb", :to => "/etc/samba/smb.conf", :sudo => true }
  after { sudo "/etc/init.d/samba restart" }
end

pkg 'samba installed' do
  installs { apt 'samba' }
  provides []
end