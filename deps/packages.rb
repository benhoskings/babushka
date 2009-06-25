
pkg_dep 'git' do
  pkg 'git-core'
end

pkg_dep 'fish'

pkg_dep 'rcconf' do
  pkg :apt => 'rcconf'
end

pkg_dep 'sed' do
  pkg :macports => 'gsed'
  provides 'gsed'
end

pkg_dep 'build-essential' do
  provides 'gcc', 'g++', 'make', 'ld'
end

pkg_dep 'autoconf'

gem_dep 'passenger' do
  provides 'passenger-install-nginx-module'
end
