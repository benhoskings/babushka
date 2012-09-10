dep 'curl.bin'

dep 'gettext.lib'

dep 'nodejs.src', :version do
  version.default!('0.6.13')
  source "http://nodejs.org/dist/node-v#{version}.tar.gz"
  provides "node ~> #{version}"
end

dep 'sudo.bin'
