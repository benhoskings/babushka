require 'spec_support'

describe String, "val_for" do
  it "space separation" do
    'key value'.val_for('key').should == 'value'
  end
  it "colon separation" do
    'key: value'.val_for('key').should == 'value'
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
    '#=> key: value'.val_for('key').should == 'value'
    '- key with spaces: value'.val_for('key with spaces').should == 'value'
    ' --  key with spaces: value'.val_for('key with spaces').should == 'value'
  end
  it "trailing characters" do
    'key: value;'.val_for('key').should == 'value'
    'key: value,'.val_for('key').should == 'value'
  end
end
