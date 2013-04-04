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
      %w[a b c].to_list(:limit => 2, :noun => 'items').should == 'a, b et al - 3 items'
    end
  end
end

describe Array, '#collapse' do
  it "should work for empty lists" do
    [].collapse('blah').should == []
    [].collapse(/blah/).should == []
  end
  it "should select surnames from a list" do
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
  it "should use the replacement if passed" do
    [
      "Chain fail2ban-nginx-catchall (1 references)",
      "target     prot opt source               destination",
      "DROP       all  --  58.161.41.76         0.0.0.0/0  ",
      "RETURN     all  --  0.0.0.0/0            0.0.0.0/0  "
    ].collapse(/^DROP\s+[^\d]+([\d\.]+)\s+.*/, '\1').should == [
      '58.161.41.76'
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
  it "should return nil for keys that don't match a group" do
    %w[cat badger narwahl pug].local_group_by(&:length)[4].should be_nil
  end
end

def version_of *args
  Babushka::VersionOf::Helpers.VersionOf *args
end


describe Array, '#versions' do
  {
    %w[a]     => [version_of('a')],
    %w[a b c] => [version_of('a'), version_of('b'), version_of('c')],
    [version_of('a')] => [version_of('a')],
    ['a 0.1', 'b >= 0.6.0', 'c ~> 2.2'] => [version_of('a', '0.1'), version_of('b', '>= 0.6.0'), version_of('c', '~> 2.2')]
  }.each_pair {|input, expected|
    it "should return #{expected.inspect} when passed #{input.inspect}" do
      input.versions.should == expected
    end
  }
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
  it "key ending in non-word characters" do
    "psql (PostgreSQL) 9.1.0".val_for('psql (PostgreSQL)').should == '9.1.0'
  end
  it "non-word leading characters" do
    '*key: value'.val_for('*key').should == 'value'
    '-key: value'.val_for('-key').should == 'value'
    '-key: value'.val_for('key').should == nil
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
  context "regexp keys" do
    it "should use the supplied regexp to match" do
      "a key: value".val_for(/key/).should == 'a : value'
    end
    it "should match cleanly with a proper key" do
      "a key: value".val_for(/^a key:/).should == 'value'
    end
    it "should match case-insensitively" do
      "Key: value".val_for(/^key:/i).should == 'value'
    end
  end
end

describe String, '#colorized?' do
  it "should return false for regular strings" do
    "babushka".should_not be_colorized
  end
  it "should return true for strings containing ANSI color sequences" do
    "\e[0;32;29mbabushka\e[0m".should be_colorized
  end
end

describe Integer, '#xsecs' do
  it "should return now for 0" do
    0.xsecs.should == 'now'
  end
  it "should return less than a minute for 12s" do
    12.xsecs.should == 'less than a minute'
  end
  it "should return 1 minute for 80s" do
    80.xsecs.should == '1 minute'
  end
  it "should return 22 minutes for 1337s" do
    1337.xsecs.should == '22 minutes'
  end
  it "should return 2 hours for 10000s" do
    10000.xsecs.should == '2 hours'
  end
  it "should return 14 days for 1234567s" do
    1234567.xsecs.should == '14 days'
  end
end
