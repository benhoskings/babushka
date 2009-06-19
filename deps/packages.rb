
pkg_dep 'git' do
  pkg 'git-core'
end

pkg_dep 'fish'

pkg_dep 'sed' do
  pkg :macports => 'gsed'
  provides 'gsed'
end

