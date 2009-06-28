
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

pkg_dep 'vim' do
  pkg :apt => 'vim-full'
end

pkg_dep 'libssl headers' do
  pkg :apt => 'libssl-dev'
  provides []
end

pkg_dep 'zlib headers' do
  pkg :apt => 'zlib1g-dev'
  provides []
end

pkg_dep 'java' do
  pkg :apt => 'sun-java6-jre'
  provides 'java'
end
