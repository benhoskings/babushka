dep 'curl.bin'

dep 'gettext.lib'

dep 'nodejs.src', :version do
  version.default!('0.8.8')
  source "http://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz"
  provides "node ~> #{version}"
end

dep 'sudo.bin'
