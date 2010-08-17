require 'spec_helper'

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
  it "oxford comma" do
    %w[a b c].to_list(:oxford => true).should == 'a, b, and c'
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

describe Array, '#collapse' do
  it "should work for empty lists" do
    [].collapse('blah').should == []
    [].collapse(/blah/).should == []
  end
  it "should select first names from a list" do
    [
      'Ben Hoskings',
      'Nathan Sampimon',
      'Nathan de Vries'
    ].collapse(/Nathan /).should == ['Sampimon', 'de Vries']
  end
  it "should strip git branch prefixes" do
    [
      '  next',
      '* master',
      '  topic'
    ].collapse(/^\* /).should == [
      'master'
    ]
  end
end

describe Array, '#local_group_by' do
  it "should work for empty lists" do
    [].group_by(&:length).should == {}
  end
  it "should do what you expect" do
    %w[cat badger narwahl pug].local_group_by(&:length).should == {
      3 => %w[cat pug],
      6 => %w[badger],
      7 => %w[narwahl]
    }
  end
  it "should work with nils and such" do
    %w[cat badger narwahl pug].local_group_by {|i|
      i[/a[rt]/]
    }.should == {
      nil => %w[badger pug],
      'at' => %w[cat],
      'ar' => %w[narwahl]
    }
  end
end

describe Array, '#local_lines' do
  it "should work for empty strings" do
    "".local_lines.should == []
  end
  it "should do what you expect" do
    "uno\ndos\ntres".local_lines.should == %w[uno dos tres]
  end
  it "should work with empty lines and such" do
    %Q{
uno
dos 

  
tres
  

    }.local_lines.should == [
      'uno',
      'dos ',
      '  ',
      'tres'
    ]
  end
end

describe Hash, '#defaults!' do
  it "should work for empty hashes" do
    {}.defaults!(:a => 'b', :c => 'd').should == {:a => 'b', :c => 'd'}
  end
  it "should work for empty defaults" do
    {:a => 'custom b', :c => 'custom d'}.defaults!({}).should == {:a => 'custom b', :c => 'custom d'}
  end
  it "should combine defaults with the hash" do
    {:a => 'custom b', :c => 'custom d'}.defaults!({:e => 'f', :g => 'h'}).should == {:a => 'custom b', :c => 'custom d', :e => 'f', :g => 'h'}
  end
  it "should override default values" do
    {:a => 'custom b', :e => 'custom e'}.defaults!({:e => 'f', :g => 'h'}).should == {:a => 'custom b', :e => 'custom e', :g => 'h'}
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