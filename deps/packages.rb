
pkg 'git' do
  pkg 'git-core'
end

pkg 'fish'

pkg 'rcconf' do
  pkg :apt => 'rcconf'
end

pkg 'sed' do
  pkg :macports => 'gsed'
  provides 'gsed'
end

pkg 'build-essential' do
  provides 'gcc', 'g++', 'make', 'ld'
end

pkg 'autoconf'

gem 'passenger' do
  provides 'passenger-install-nginx-module'
end

pkg 'vim'

pkg 'libssl headers' do
  pkg :apt => 'libssl-dev'
  provides []
end

pkg 'zlib headers' do
  pkg :apt => 'zlib1g-dev'
  provides []
end

pkg 'java' do
  pkg :apt => 'sun-java6-jre'
  provides 'java'
  after { shell("set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun") }
end
