def mock_sources
  @source1 = Source.new nil, :name => 'source_1'
  @source2 = Source.new nil, :name => 'source_2'
  [Base.sources.anonymous, Base.sources.core, @source1, @source2].each {|s| s.stub!(:load!) }
  Source.stub!(:present).and_return [@source1, @source2]

  Base.sources.load_context :source => Base.sources.anonymous do
    @anonymous_meta = meta 'anonymous_meta'
  end
  Base.sources.load_context :source => Base.sources.core do
    @core_meta = meta 'core_meta'
    @core_from = meta 'core_from'
  end
  Base.sources.load_context :source => @source1 do
    @meta1 = meta :meta_1
    @meta2 = meta 'meta_2'
    @from1 = meta 'from_test'
  end
  Base.sources.load_context :source => @source2 do
    @meta3 = meta :meta_3
    @meta4 = meta 'meta_4'
    @from2 = meta 'from_test'
    @from2_2 = meta 'from_test_2'
  end
end

def mock_dep dep_name, opts
  Base.sources.load_context :source => opts[:in] do
    dep dep_name, :template => opts[:template]
  end
end
