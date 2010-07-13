dep 'xcode tools', :template => 'external' do
  expects 'gcc', 'g++', 'autoconf', 'make', 'ld'
  otherwise {
    log_and_open "Install Xcode, and then run Babushka again.", "http://developer.apple.com/technology/xcode.html"
  }
end

dep 'llvm in path', :for => :snow_leopard do
  requires 'xcode tools'
  met? { which 'llvm-gcc-4.2' }
  meet {
    in_dir('/usr/local/bin') {|path|
      shell "ln -s /Developer/usr/llvm-gcc-4.2/bin/llvm* .", :sudo => !path.writable?
    }
  }
end
