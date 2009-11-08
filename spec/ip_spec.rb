require 'spec/spec_support'

describe "IP" do
  it "should work for valid IPs" do
    [
      '10.0.1.1'      ,
      '192.168.0.1'   ,
      '174.129.110.43'
    ].each {|string|
      IP.new(string).should be_valid
    }
  end
  it "should work for invalid IPs" do
    [
      '10.0.1.'        ,
      '.10.0.1'        ,
      '192.168.0'      ,
      '192.168.0.c'    ,
      '174.129.110.433'
    ].each {|string|
      IP.new(string).should_not be_valid
    }
  end
end

describe "IPRange" do
  it "should work for valid IPs" do
    [
      '10.0.1.x'   ,
      '10.0.x'     ,
      '174.129.x.x'
    ].each {|string|
      IPRange.new(string).should be_valid
    }
  end
  it "should work for invalid IPs" do
    [
      '10.0.1.1'    ,
      '10.0.x.1'    ,
      '10.0.x.'     ,
      '174.129.110.',
      '174.129.x.43'
    ].each {|string|
      IPRange.new(string).should_not be_valid
    }
  end
end
