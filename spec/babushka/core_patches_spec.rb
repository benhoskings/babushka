# coding: utf-8

require 'spec_helper'

RSpec.describe Array, "to_list" do
  it "no elements" do
    expect([].to_list).to eq('')
  end
  it "single element" do
    expect(%w[a].to_list).to eq('a')
  end
  it "two elements" do
    expect(%w[a b].to_list).to eq('a and b')
  end
  it "three elements" do
    expect(%w[a b c].to_list).to eq('a, b and c')
  end
  it "oxford comma" do
    expect(%w[a b c].to_list(:oxford => true)).to eq('a, b, and c')
  end
  it "custom conjugation" do
    expect(%w[a b c].to_list(:conj => 'or')).to eq('a, b or c')
  end
end

RSpec.describe Array, '#collapse' do
  it "should work for empty lists" do
    expect([].collapse('blah')).to eq([])
    expect([].collapse(/blah/)).to eq([])
  end
  it "should select surnames from a list" do
    expect([
      'Ben Hoskings',
      'Nathan Sampimon',
      'Nathan de Vries'
    ].collapse(/Nathan /)).to eq(['Sampimon', 'de Vries'])
  end
  it "should strip git branch prefixes" do
    expect([
      '  next',
      '* master',
      '  topic'
    ].collapse(/^\* /)).to eq([
      'master'
    ])
  end
  it "should use the replacement if passed" do
    expect([
      "Chain fail2ban-nginx-catchall (1 references)",
      "target     prot opt source               destination",
      "DROP       all  --  58.161.41.76         0.0.0.0/0  ",
      "RETURN     all  --  0.0.0.0/0            0.0.0.0/0  "
    ].collapse(/^DROP\s+[^\d]+([\d\.]+)\s+.*/, '\1')).to eq([
      '58.161.41.76'
    ])
  end
end

RSpec.describe Array, '#local_group_by' do
  it "should work for empty lists" do
    expect([].group_by(&:length)).to eq({})
  end
  it "should do what you expect" do
    expect(%w[cat badger narwahl pug].local_group_by(&:length)).to eq({
      3 => %w[cat pug],
      6 => %w[badger],
      7 => %w[narwahl]
    })
  end
  it "should work with nils and such" do
    expect(%w[cat badger narwahl pug].local_group_by {|i|
      i[/a[rt]/]
    }).to eq({
      nil => %w[badger pug],
      'at' => %w[cat],
      'ar' => %w[narwahl]
    })
  end
  it "should return nil for keys that don't match a group" do
    expect(%w[cat badger narwahl pug].local_group_by(&:length)[4]).to be_nil
  end
end

def version_of *args
  Babushka::VersionOf::Helpers.VersionOf *args
end


RSpec.describe Array, '#versions' do
  {
    %w[a]     => [version_of('a')],
    %w[a b c] => [version_of('a'), version_of('b'), version_of('c')],
    [version_of('a')] => [version_of('a')],
    ['a 0.1', 'b >= 0.6.0', 'c ~> 2.2'] => [version_of('a', '0.1'), version_of('b', '>= 0.6.0'), version_of('c', '~> 2.2')]
  }.each_pair {|input, expected|
    it "should return #{expected.inspect} when passed #{input.inspect}" do
      expect(input.versions).to eq(expected)
    end
  }
end

RSpec.describe Hash, '#defaults!' do
  it "should work for empty hashes" do
    expect({}.defaults!(:a => 'b', :c => 'd')).to eq({:a => 'b', :c => 'd'})
  end
  it "should work for empty defaults" do
    expect({:a => 'custom b', :c => 'custom d'}.defaults!({})).to eq({:a => 'custom b', :c => 'custom d'})
  end
  it "should combine defaults with the hash" do
    expect({:a => 'custom b', :c => 'custom d'}.defaults!({:e => 'f', :g => 'h'})).to eq({:a => 'custom b', :c => 'custom d', :e => 'f', :g => 'h'})
  end
  it "should override default values" do
    expect({:a => 'custom b', :e => 'custom e'}.defaults!({:e => 'f', :g => 'h'})).to eq({:a => 'custom b', :e => 'custom e', :g => 'h'})
  end
end

RSpec.describe Array, '#val_for' do
  it "space separation" do
    expect(['key value'].val_for('key')).to eq('value')
  end
  it "key/value separation" do
    expect(['key: value'].val_for('key')).to eq('value')
    expect(['key = value'].val_for('key')).to eq('value')
  end
  it "whitespace" do
    expect(['  key value '].val_for('key')).to eq('value')
  end
  it "whitespace in key" do
    expect(['space-separated key: value'].val_for('space-separated key')).to eq('value')
  end
  it "whitespace in value" do
    expect(['key: space-separated value'].val_for('key')).to eq('space-separated value')
  end
  it "whitespace in both" do
    expect(['key with spaces: space-separated value'].val_for('key with spaces')).to eq('space-separated value')
  end
  it "key ending in non-word characters" do
    expect(["psql (PostgreSQL) 9.1.0"].val_for('psql (PostgreSQL)')).to eq('9.1.0')
  end
  it "non-word leading characters" do
    expect(['*key: value'].val_for('*key')).to eq('value')
    expect(['-key: value'].val_for('-key')).to eq('value')
    expect(['-key: value'].val_for('key')).to eq(nil)
  end
  it "non-word leading tokens" do
    expect(['* key: value'].val_for('key')).to eq('value')
    expect(['- key with spaces: value'].val_for('key with spaces')).to eq('value')
    expect([' --  key with spaces: value'].val_for('key with spaces')).to eq('value')
  end
  it "trailing characters" do
    expect(['key: value;'].val_for('key')).to eq('value')
    expect(['key: value,'].val_for('key')).to eq('value')
  end
  it "paths" do
    expect(["/dev/disk1s2        	Apple_HFS                        /Volumes/TextMate 1.5.9"].val_for("/dev/disk1s2        	Apple_HFS")).to eq("/Volumes/TextMate 1.5.9")
    expect(["/dev/disk1s2        	Apple_HFS                        /Volumes/TextMate 1.5.9"].val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/)).to eq("/Volumes/TextMate 1.5.9")
  end
  context "regexp keys" do
    it "should use the supplied regexp to match" do
      expect(["a key: value"].val_for(/key/)).to eq('a : value')
    end
    it "should match cleanly with a proper key" do
      expect(["a key: value"].val_for(/^a key:/)).to eq('value')
    end
    it "should match case-insensitively" do
      expect(["Key: value"].val_for(/^key:/i)).to eq('value')
    end
  end
end

RSpec.describe String, '#to_utf8' do
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
      expect(valid_ascii.encoding).to eq(Encoding::ASCII)
      expect(valid_ascii.to_utf8).to eq("konnichiwa")
      expect(valid_ascii.to_utf8.encoding).to eq(Encoding::UTF_8)
    end
    it "should leave UTF-8 strings untouched" do
      expect(valid_utf8.encoding).to eq(Encoding::UTF_8)
      expect(valid_utf8.to_utf8).to eq("こんにちは")
      expect(valid_utf8.to_utf8.encoding).to eq(Encoding::UTF_8)
    end
    # TODO: This case might be better handled by assuming the string is UTF-8, but
    # I'm going to leave the logic stupid for now and improve it later.
    it "should respect mislabelled strings" do
      expect(valid_utf8_mislabelled.encoding).to eq(Encoding::ASCII)
      expect(valid_utf8_mislabelled.to_utf8).to eq("???????????????")
      expect(valid_utf8_mislabelled.to_utf8.encoding).to eq(Encoding::UTF_8)
    end
    it "should convert invalid strings" do
      expect(invalid.encoding).to eq(Encoding::ASCII)
      expect(invalid.to_utf8).to eq("lol?")
      expect(invalid.to_utf8.encoding).to eq(Encoding::UTF_8)
    end
  end
end

RSpec.describe Integer, '#xsecs' do
  it "should handle 0" do
    expect(0.xsecs).to eq('now')
  end
  it "should work for seconds" do
    expect(3.xsecs).to eq('less than a minute')
    expect(59.xsecs).to eq('less than a minute')
  end
  it "should work for minutes" do
    expect(60.xsecs).to eq('1 minute')
    expect((3600-1).xsecs).to eq('59 minutes')
  end
  it "should work for hours" do
    expect(3600.xsecs).to eq('1 hour')
    expect((3600*24 - 1).xsecs).to eq('23 hours')
  end
  it "should work for days" do
    expect((3600*24).xsecs).to eq('1 day')
    expect((3600*24*7 - 1).xsecs).to eq('6 days')
  end
  it "should work for weeks" do
    expect((3600*24*7).xsecs).to eq('1 week')
    expect((3600*24*27 - 1).xsecs).to eq('3 weeks')
  end
  it "should work for months" do
    expect((3600*24*28).xsecs).to eq('1 month')
    expect((3600*24*360 - 1).xsecs).to eq('11 months')
  end
  it "should work for years" do
    expect((3600*24*365).xsecs).to eq('1 year')
    expect((3600*24*365*20).xsecs).to eq('20 years')
  end
end
