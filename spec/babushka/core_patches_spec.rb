require 'spec_support'

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