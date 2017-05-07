class AcceptsForTest
  include Babushka::AcceptsListFor
  include Babushka::AcceptsValueFor

  attr_reader :payload

  def initialize name = nil
    @name = name
    @payload = {}
  end

  def chooser
    :brew
  end

  def chooser_choices
    [:apt, :brew]
  end

  def default_formats
    %w[html xml js json]
  end

  def default_format
    "json"
  end

  accepts_value_for :package, :choose_with => :via
  accepts_value_for :renders, "a default response", :choose_with => :via
  accepts_value_for :format, :default_format, :choose_with => :via
  accepts_value_for :do_cleanup, false, :choose_with => :via
  accepts_value_for :do_backup, true, :choose_with => :via

  accepts_list_for :records, :choose_with => :via
  accepts_list_for :produces, "a default response", :choose_with => :via
  accepts_list_for :valid_formats, :default_formats, :choose_with => :via
end

def test_lists
  {
    nil         => [],
    []          => [],
    true        => [true],
    false       => [false],
    'a'         => ['a'],
    %w[a]       => ['a'],
    %w[a b c]   => ['a', 'b', 'c']
  }
end

def test_value_lambdas
  {
    proc{ } => nil,
    proc{
      via :apt, "git-core"
    } => nil,
    proc{
      via :brew, 'ruby'
      via :apt, 'git-core'
    } => 'ruby',
    proc{
      via :brew, 'something else'
      via :apt, 'some apt packages'
    } => 'something else'
  }
end

def test_list_lambdas
  {
    proc{ } => [],
    proc{
      via :apt, %w[ruby irb ri rdoc]
    } => [],
    proc{
      via :brew, 'ruby'
      via :apt, %w[ruby irb ri rdoc]
    } => ['ruby'],
    proc{
      via :brew, 'something else'
      via :apt, 'some apt packages'
    } => ['something else']
  }
end
