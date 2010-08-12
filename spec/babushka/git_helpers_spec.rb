require 'spec_support'

def stub_repo name = 'a'
  in_dir tmp_prefix / 'repos' / name, :create => true do
    shell 'git init'
    shell 'echo "Hello from the babushka specs!" >> content.txt'
    shell 'git add .'
    shell 'git commit -m "Initial commit, by the spec suite."'
  end
end

describe "cloning" do
  before { stub_repo }
  it "should clone a repo" do
    # TODO actually implement this
  end
end
