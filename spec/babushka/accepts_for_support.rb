class AcceptsForTest
  include AcceptsListFor
  include AcceptsValueFor
  attr_reader :payload
  def initialize name = nil
    @name = name
    @payload = {}
  end
  def chooser
    :macports
  end
  def chooser_choices
    [:apt, :macports]
  end
  def default_formats
    %w[html xml js json]
  end
  def default_format
    "json"
  end
  def self.set_up_delegating_for method_name
    # nothing to do
  end
  accepts_value_for :package, :choose_with => :via
  accepts_value_for :renders, "a default response", :choose_with => :via
  accepts_value_for :format, :default_format, :choose_with => :via

  accepts_list_for :records, :choose_with => :via
  accepts_list_for :produces, "a default response", :choose_with => :via
  accepts_list_for :valid_formats, :default_formats, :choose_with => :via
end

def test_lists
  {
    'a'       => ['a'],
    %w[a]     => ['a'],
    %w[a b c] => ['a', 'b', 'c'],
    # {'a' => '0.1', 'b' => '0.2.3'} => [ver('a', '0.1'), ver('b', '0.2.3')],
  }
end

def test_value_lambdas
  {
    L{ } => nil,
    L{
      via :apt, "git-core"
    } => nil,
    L{
      via :macports, 'ruby'
      via :apt, 'git-core'
    } => 'ruby',
    L{
      via :macports, 'something else'
      via :apt, 'some apt packages'
    } => 'something else'
  }
end

def test_list_lambdas
  {
    L{ } => [],
    L{
      via :apt, %w[ruby irb ri rdoc]
    } => [],
    L{
      via :macports, 'ruby'
      via :apt, %w[ruby irb ri rdoc]
    } => ['ruby'],
    L{
      via :macports, 'something else'
      via :apt, 'some apt packages'
    } => ['something else']
  }
end
