
pkg_dep 'git' do
  pkg 'git-core'
end

pkg_dep 'fish'

pkg_dep 'sed' do
  pkg :macports => 'gsed'
  provides 'gsed'
end

pkg_dep 'build-essential' do
  provides 'gcc', 'g++', 'autoconf', 'make', 'automake', 'ld'
end
