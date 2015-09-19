# coding: utf-8

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

describe Array, '#val_for' do
  it "space separation" do
    ['key value'].val_for('key').should == 'value'
  end
  it "key/value separation" do
    ['key: value'].val_for('key').should == 'value'
    ['key = value'].val_for('key').should == 'value'
  end
  it "whitespace" do
    ['  key value '].val_for('key').should == 'value'
  end
  it "whitespace in key" do
    ['space-separated key: value'].val_for('space-separated key').should == 'value'
  end
  it "whitespace in value" do
    ['key: space-separated value'].val_for('key').should == 'space-separated value'
  end
  it "whitespace in both" do
    ['key with spaces: space-separated value'].val_for('key with spaces').should == 'space-separated value'
  end
  it "key ending in non-word characters" do
    ["psql (PostgreSQL) 9.1.0"].val_for('psql (PostgreSQL)').should == '9.1.0'
  end
  it "non-word leading characters" do
    ['*key: value'].val_for('*key').should == 'value'
    ['-key: value'].val_for('-key').should == 'value'
    ['-key: value'].val_for('key').should == nil
  end
  it "non-word leading tokens" do
    ['* key: value'].val_for('key').should == 'value'
    ['- key with spaces: value'].val_for('key with spaces').should == 'value'
    [' --  key with spaces: value'].val_for('key with spaces').should == 'value'
  end
  it "trailing characters" do
    ['key: value;'].val_for('key').should == 'value'
    ['key: value,'].val_for('key').should == 'value'
  end
  it "paths" do
    ["/dev/disk1s2        	Apple_HFS                        /Volumes/TextMate 1.5.9"].val_for("/dev/disk1s2        	Apple_HFS").should == "/Volumes/TextMate 1.5.9"
    ["/dev/disk1s2        	Apple_HFS                        /Volumes/TextMate 1.5.9"].val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/).should == "/Volumes/TextMate 1.5.9"
  end
  context "regexp keys" do
    it "should use the supplied regexp to match" do
      ["a key: value"].val_for(/key/).should == 'a : value'
    end
    it "should match cleanly with a proper key" do
      ["a key: value"].val_for(/^a key:/).should == 'value'
    end
    it "should match case-insensitively" do
      ["Key: value"].val_for(/^key:/i).should == 'value'
    end
  end
end

describe String, '#to_utf8' do
  if "".respond_to?(:encoding) # Skip these tests on ruby-1.8.

    let(:valid_utf8) { "こんにちは".force_encoding('utf-8') }
    let(:valid_utf8_mislabelled) { "こんにちは".force_encoding('ascii') }
    let(:valid_ascii) { "konnichiwa".force_encoding('ascii') }
    let(:invalid) { "lol\xFF".force_encoding('ascii') }

    it "should make sure :valid_utf8 is really utf8" do
      expect { valid_utf8.encode('ascii') }.to raise_error(Encoding::UndefinedConversionError)
    end
    it "should make sure :invalid is really invalid" do
      expect { invalid.encode('utf-8') }.to raise_error(Encoding::InvalidByteSequenceError)
    end

    it "should convert ASCII strings to utf8" do
      valid_ascii.encoding.should == Encoding::ASCII
      valid_ascii.to_utf8.should == "konnichiwa"
      valid_ascii.to_utf8.encoding.should == Encoding::UTF_8
    end
    it "should leave UTF-8 strings untouched" do
      valid_utf8.encoding.should == Encoding::UTF_8
      valid_utf8.to_utf8.should == "こんにちは"
      valid_utf8.to_utf8.encoding.should == Encoding::UTF_8
    end
    # TODO: This case might be better handled by assuming the string is UTF-8, but
    # I'm going to leave the logic stupid for now and improve it later.
    it "should respect mislabelled strings" do
      valid_utf8_mislabelled.encoding.should == Encoding::ASCII
      valid_utf8_mislabelled.to_utf8.should == "???????????????"
      valid_utf8_mislabelled.to_utf8.encoding.should == Encoding::UTF_8
    end
    it "should convert invalid strings" do
      invalid.encoding.should == Encoding::ASCII
      invalid.to_utf8.should == "lol?"
      invalid.to_utf8.encoding.should == Encoding::UTF_8
    end
  end
end

describe Integer, '#xsecs' do
  it "should handle 0" do
    0.xsecs.should == 'now'
  end
  it "should work for seconds" do
    3.xsecs.should == 'less than a minute'
    59.xsecs.should == 'less than a minute'
  end
  it "should work for minutes" do
    60.xsecs.should == '1 minute'
    (3600-1).xsecs.should == '59 minutes'
  end
  it "should work for hours" do
    3600.xsecs.should == '1 hour'
    (3600*24 - 1).xsecs.should == '23 hours'
  end
  it "should work for days" do
    (3600*24).xsecs.should == '1 day'
    (3600*24*7 - 1).xsecs.should == '6 days'
  end
end
