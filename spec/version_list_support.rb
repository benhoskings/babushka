class VersionListTest
  include VersionList
  attr_reader :payload
  def initialize name = nil
    @name = name
    @payload = {}
  end
  def chooser
    :macports
  end
  def default_formats
    %w[html xml js json]
  end
  accepts_list_for :records
  accepts_list_for :produces, "a default response"
  accepts_list_for :valid_formats, :default_formats
end

def test_lists
  {
    'a'       => %w[a],
    %w[a]     => %w[a],
    %w[a b c] => %w[a b c],
    {'a' => '0.1', 'b' => '0.2.3'} => {'a' => '0.1', 'b' => '0.2.3'},
  }
end

def test_lambdas
  {
    L{ } => [],
    L{
      apt %w[ruby irb ri rdoc]
    } => [],
    L{
      macports 'ruby'
      apt %w[ruby irb ri rdoc]
    } => %w[ruby],
    L{
      macports %w[something else]
      apt %w[some apt packages]
    } => %w[something else]
  }
end
