require 'spec_helper'
require 'timeout'

RSpec.describe Babushka::Shell, "arguments" do
  it "should reject calls with no arguments, since exec will explode anyway" do
    expect(L{ Babushka::Shell.new }).to raise_error(ArgumentError, "wrong number of arguments (0 for 1+)")
  end
end

RSpec.describe Babushka::Shell, '#ok?' do
  it "should return true on success" do
    expect(Babushka::Shell.new('true', {}).run(&:ok?)).to be_truthy
  end
  it "should return false on failure" do
    expect(Babushka::Shell.new('false', {}).run(&:ok?)).to be_falsey
  end
end

RSpec.describe Babushka::Shell, '#result' do
  it "should return zero on success" do
    expect(Babushka::Shell.new('true', {}).run(&:result)).to eq(0)
  end
  it "should return non-zero on failure" do
    expect(Babushka::Shell.new('false', {}).run(&:result)).to eq(1)
  end
end

RSpec.describe Babushka::Shell do
  it "should close stdin, so subprocesses don't wait for input forever" do
    Timeout::timeout(1) do
      expect(Babushka::Shell.new('cat', {}).run(&:result)).to eq(0)
    end
  end
end
