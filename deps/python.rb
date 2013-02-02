dep 'python.bin' do
  provides {
    via :brew, 'python', 'pip' # homebrew installs pip along with python.
    otherwise 'python'
  }
end
