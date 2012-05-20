dep 'build tools' do
  requires {
    on :osx, 'xcode commandline tools'
    on :yum, dep('gcc'), dep('gcc-c++'), dep('autoconf.bin'), dep('automake.bin'), dep('libtool.bin')
    on :linux, 'build-essential', dep('autoconf.bin'), dep('automake.bin'), dep('libtool.bin')
  }
end

dep 'build-essential', :template => 'managed' do
  provides 'gcc', 'g++', 'make', 'ld'
end

dep 'xcode tools', :template => 'external' do
  expects 'gcc', 'g++', 'autoconf', 'make', 'ld'
  otherwise {
    log_and_open "Install Xcode, and then run Babushka again.", "http://developer.apple.com/technology/xcode.html"
  }
end

dep 'xcode commandline tools', :template => 'installer' do
  # These pkgs consist of the packages inside the Xcode installer that contain the
  # commandline tools and compiler toolchain. They're not a custom build - they're
  # unmodified from the original Xcode install; just a subset (i.e. excluding the
  # packages for things like Interface Builder and Xcode.app).
  #
  # See http://github.com/kennethreitz/osx-gcc-installer for more info.
  source {
    on :lion,         'https://github.com/downloads/kennethreitz/osx-gcc-installer/GCC-10.7-v2.pkg'
    on :snow_leopard, 'https://github.com/downloads/kennethreitz/osx-gcc-installer/GCC-10.6.pkg'
  }
  provides %w[cc gcc c++ g++ llvm-gcc llvm-g++ clang] # compilers
  provides %w[ld libtool] # linkety link
  provides %w[make] # configure and build tools
  provides %w[cpp m4 nasm yacc bison] # misc - the preprocessor, assembler, grammar stuff
end
