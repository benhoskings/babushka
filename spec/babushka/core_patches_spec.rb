require 'spec_support'

describe Array, "to_list" do
  it "no elements" do
    [].to_list.should == ''
  end
  it "single element" do
    %w[a].to_list.should == 'a'
  end
  it "two elements" do
    %w[a b].to_list.should == 'a and b'
  end
  it "three elements" do
    %w[a b c].to_list.should == 'a, b and c'
  end
  it "custom conjugation" do
    %w[a b c].to_list(:conj => 'or').should == 'a, b or c'
  end
  describe "limits" do
    it "below limit" do
      %w[a b c].to_list(:limit => 4).should == 'a, b and c'
    end
    it "at limit" do
      %w[a b c].to_list(:limit => 3).should == 'a, b and c'
    end
    it "above limit" do
      %w[a b c].to_list(:limit => 2).should == 'a, b et al'
      %w[a b c d e].to_list(:limit => 4).should == 'a, b, c, d et al'
    end
    it "with noun" do
      %w[a b c].to_list(:limit => 2, :noun => 'items').should == 'a, b et al &mdash; 3 items'
    end
  end
end

describe String, "val_for" do
  it "space separation" do
    'key value'.val_for('key').should == 'value'
  end
  it "key/value separation" do
    'key: value'.val_for('key').should == 'value'
    'key = value'.val_for('key').should == 'value'
  end
  it "whitespace" do
    '  key value '.val_for('key').should == 'value'
  end
  it "whitespace in key" do
    'space-separated key: value'.val_for('space-separated key').should == 'value'
  end
  it "whitespace in value" do
    'key: space-separated value'.val_for('key').should == 'space-separated value'
  end
  it "whitespace in both" do
    'key with spaces: space-separated value'.val_for('key with spaces').should == 'space-separated value'
  end
  it "non-word leading characters" do
    '*key: value'.val_for('*key').should == 'value'
    '-key: value'.val_for('-key').should == 'value'
    '-key: value'.val_for('key').should == ''
  end
  it "non-word leading tokens" do
    '* key: value'.val_for('key').should == 'value'
    '- key with spaces: value'.val_for('key with spaces').should == 'value'
    ' --  key with spaces: value'.val_for('key with spaces').should == 'value'
  end
  it "trailing characters" do
    'key: value;'.val_for('key').should == 'value'
    'key: value,'.val_for('key').should == 'value'
  end
  it "paths" do
    "/dev/disk1s2        	Apple_HFS                      	/Volumes/TextMate 1.5.9".val_for("/dev/disk1s2        	Apple_HFS").should == "/Volumes/TextMate 1.5.9"
    "/dev/disk1s2        	Apple_HFS                      	/Volumes/TextMate 1.5.9".val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/).should == "/Volumes/TextMate 1.5.9"
  end
end

describe String, "camelize" do
  it "should convert underscored strings to CamelCase" do
    {
      "test" => "Test",
      "testy_test" => "TestyTest",
      "Test" => "Test",
      "TestyTest" => "TestyTest"
    }.each_pair {|k,v|
      k.camelize.should == v
    }
  end
end