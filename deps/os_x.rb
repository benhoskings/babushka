ext 'xcode tools' do
  if_missing 'gcc', 'g++', 'autoconf', 'make', 'ld' do
    log_and_open "Install Xcode, and then run Babushka again.",
      "http://developer.apple.com/technology/xcode.html"
    :fail
  end
end

dep 'llvm in path', :for => :snow_leopard do
  requires 'xcode tools'
  met? { which 'llvm-gcc-4.2' }
  meet {
    in_dir(llvm_bin_path = '/usr/local/bin') {
      shell "ln -s /Developer/usr/llvm-gcc-4.2/bin/llvm* .", :sudo => !File.writable?(llvm_bin_path)
    }
  }
end
