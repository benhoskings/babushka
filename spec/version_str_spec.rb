require 'spec/spec_support'

def compare_with operator
  pairs.zip(results[operator]).each {|pair,expected|
    result = VersionStr.new(pair.first).send operator, VersionStr.new(pair.last)
    it "#{pair.first} #{operator} #{pair.last}: #{result}" do
      expected.should == result
    end
  }
end

def pairs
  [
    %w[0.3.1    0.3.1],
    %w[0.3.1    0.3.2],
    %w[0.3.1    0.3.1.10],
    %w[0.3.1.1  0.3.1.10],
    %w[0.3.1.9  0.3.1.10],
    %w[0.3.1.9  0.3.0.10],
    %w[0.3.1    0.3.0.10],
    %w[0.3.1.9  1],
    %w[0.3.1.9  0.4],
    %w[0.3.1.9  0.3.2],
    %w[0.3.1.9  0.3.0],
    %w[1        0.3.1.9],
    %w[0.4      0.3.1.9],
    %w[0.3.2    0.3.1.9],
    %w[0.3.2    0.3.1],
    %w[0.3.1.10 0.3.1.9],
    %w[0.3.1    0.3],
    %w[0.3.1    0.4],
  ]
end

def t; true end
def f; false end

def results
  {
    "==" => [t, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f],
    "!=" => [f, t, t, t, t, t, t, t, t, t, t, t, t, t, t, t, t, t],
    ">"  => [f, f, f, f, f, t, t, f, f, f, t, t, t, t, t, t, t, f],
    "<"  => [f, t, t, t, t, f, f, t, t, t, f, f, f, f, f, f, f, t],
    ">=" => [t, f, f, f, f, t, t, f, f, f, t, t, t, t, t, t, t, f],
    "<=" => [t, t, t, t, t, f, f, t, t, t, f, f, f, f, f, f, f, t],
    "~>" => [t, f, f, f, f, f, f, f, f, f, t, f, f, f, t, t, t, f]
  }
end

%w[== != > < >= <= ~>].each do |operator|
  describe operator do
    compare_with operator
  end
end
