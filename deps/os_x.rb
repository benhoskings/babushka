ext_dep 'xcode tools' do
  if_missing 'gcc', 'g++', 'autoconf', 'automake', 'ld' do
    log_and_open "Install Xcode, and then run Babushka again.",
      "http://developer.apple.com/technology/xcode.html"
  end
end
