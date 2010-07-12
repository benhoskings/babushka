def mock_sources
  @source1 = Source.new nil, :name => 'source_1'
  @source2 = Source.new nil, :name => 'source_2'
  [Base.sources.anonymous, Base.sources.core, @source1, @source2].each {|s| s.stub!(:load!) }
  Source.stub!(:present).and_return [@source1, @source2]

  DepDefiner.load_context :source => Base.sources.anonymous do
    @anonymous_meta = meta 'anonymous meta'
  end
  DepDefiner.load_context :source => Base.sources.core do
    @core_meta = meta 'core_meta'
    @core_from = meta 'core from'
  end
  DepDefiner.load_context :source => @source1 do
    @meta1 = meta 'meta_1'
    @meta2 = meta 'meta 2'
    @from1 = meta 'from test'
  end
  DepDefiner.load_context :source => @source2 do
    @meta3 = meta 'meta_3'
    @meta4 = meta 'meta 4'
    @from2 = meta 'from test'
    @from2_2 = meta 'from test 2'
  end
end
