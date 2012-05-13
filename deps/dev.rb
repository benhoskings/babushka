dep 'build tools' do
  requires {
    on :osx, 'xcode commandline tools'
    on :snow_leopard, 'llvm in path'
    on :yum, dep('gcc'), dep('gcc-c++'), dep('autoconf.bin'), dep('automake.bin'), dep('libtool.bin')
    on :linux, 'build-essential', dep('autoconf.bin'), dep('automake.bin'), dep('libtool.bin')
  }
end

dep 'build-essential', :template => 'managed' do
  provides 'gcc', 'g++', 'make', 'ld'
end
