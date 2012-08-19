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

dep 'xcode commandline tools', :template => 'external' do
  # See http://kennethreitz.com/xcode-gcc-and-homebrew.html
  expects %w[cc gcc c++ g++ llvm-gcc llvm-g++ clang] # compilers
  expects %w[ld libtool] # linkety link
  expects %w[make] # configure and build tools
  expects %w[cpp m4 nasm yacc bison] # misc - the preprocessor, assembler, grammar stuff
  otherwise {
    log_and_open "Install Command Line Tools for Xcode, and then run Babushka again.",
                 "http://developer.apple.com/downloads"
  }
end
