
pkg 'git' do
  installs 'git-core'
end

pkg 'fish'

pkg 'rcconf' do
  installs :apt => 'rcconf'
end

pkg 'sed' do
  installs :macports => 'gsed'
  provides 'gsed'
end

pkg 'wget'

pkg 'build-essential' do
  provides 'gcc', 'g++', 'make', 'ld'
end

pkg 'autoconf'

gem 'passenger' do
  provides 'passenger-install-nginx-module'
end

pkg 'vim'

pkg 'libssl headers' do
  installs :apt => 'libssl-dev'
  provides []
end

pkg 'zlib headers' do
  installs :apt => 'zlib1g-dev'
  provides []
end

pkg 'java' do
  installs :apt => 'sun-java6-jre'
  provides 'java'
  after { shell("set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun") }
end
