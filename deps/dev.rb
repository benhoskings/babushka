dep 'build tools' do
  requires {
    on :osx, 'xcode commandline tools'
    on :linux, 'linux build tools'
  }
end

dep 'linux build tools', :template => 'bin' do
  installs {
    via :yum, %w[gcc gcc-c++ autoconf automake libtool]
    via :apt, %w[build-essential autoconf automake libtool]
  }
  provides %w[gcc g++ make ld autoconf automake libtool]
end

dep 'xcode tools', :template => 'external' do
  expects 'gcc', 'g++', 'autoconf', 'make', 'ld'
  otherwise {
    log "Install Xcode, and then run Babushka again."
    log "Official download at http://developer.apple.com/technology/xcode.html"
    confirm "Open in browser now" do
      shell "open http://developer.apple.com/technology/xcode.html"
    end
  }
end

dep 'xcode commandline tools', :template => 'external' do
  # See http://kennethreitz.com/xcode-gcc-and-homebrew.html
  expects %w[cc gcc c++ g++ llvm-gcc llvm-g++ clang] # compilers
  expects %w[ld libtool] # linkety link
  expects %w[make] # configure and build tools
  expects %w[cpp m4 nasm yacc bison] # misc - the preprocessor, assembler, grammar stuff
  otherwise {
    log "Install Command Line Tools for Xcode, and then run Babushka again."
    log "Official pacakge at http://developer.apple.com/downloads"
    confirm "Open in browser now" do
      shell "open http://developer.apple.com/downloads"
    end
  }
end
