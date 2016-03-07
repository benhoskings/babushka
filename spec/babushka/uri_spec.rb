require 'spec_helper'

RSpec.describe URI, "escaping" do
  it "should escape URLs" do
    expect(URI.escape("http://babushka.me/babushka snapshot.tgz")).to eq("http://babushka.me/babushka%20snapshot.tgz")
  end
  it "should not escape twice" do
    expect(URI.escape("http://babushka.me/babushka%20snapshot.tgz")).to eq("http://babushka.me/babushka%20snapshot.tgz")
  end
  it "should handle partially escaped urls" do
    expect(URI.escape("http://babushka.me/ok this is%20just%20a mess.tgz")).to eq("http://babushka.me/ok%20this%20is%20just%20a%20mess.tgz")
  end
end
