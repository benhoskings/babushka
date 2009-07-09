pkg 'autoconf'
pkg 'build-essential' do
  provides 'gcc', 'g++', 'make', 'ld'
end
pkg 'fish'
pkg 'git' do
  installs 'git-core'
end
pkg 'java' do
  installs { apt 'sun-java6-jre' }
  provides 'java'
  after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
end
pkg 'libssl headers' do
  installs { apt 'libssl-dev' }
  provides []
end
gem 'passenger' do
  provides 'passenger-install-nginx-module'
end
pkg 'rcconf' do
  installs { apt 'rcconf' }
end
pkg 'sed' do
  installs { macports 'gsed' }
  provides 'gsed'
end
pkg 'vim'
pkg 'wget'
pkg 'zlib headers' do
  installs { apt 'zlib1g-dev' }
  provides []
end
