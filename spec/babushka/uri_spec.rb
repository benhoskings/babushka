require 'spec_helper'

describe URI, "escaping" do
  it "should escape URLs" do
    URI.escape("http://babushka.me/babushka snapshot.tgz").should == "http://babushka.me/babushka%20snapshot.tgz"
  end
  it "should not escape twice" do
    URI.escape("http://babushka.me/babushka%20snapshot.tgz").should == "http://babushka.me/babushka%20snapshot.tgz"
  end
  it "should handle partially escaped urls" do
    URI.escape("http://babushka.me/ok this is%20just%20a mess.tgz").should == "http://babushka.me/ok%20this%20is%20just%20a%20mess.tgz"
  end
end
