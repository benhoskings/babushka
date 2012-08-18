dep 'test dep 1' do
end

dep 'externally templated', :template => 'nested source:test_template' do
end

meta 'local_template' do
  accepts_list_for :uri
end

dep 'locally templated', :template => 'local_template' do
  uri 'http://local.test.org'
end

dep 'locally templated.local_template' do
  uri 'http://local.test.org'
end
