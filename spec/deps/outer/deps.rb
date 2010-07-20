dep 'test dep 1' do
  
end

dep 'templated test dep 1', :template => 'nested source:test_template' do
  
end

meta 'meta within this source' do
  accepts_list_for :uri
end

dep 'locally templated dep' do
  uri 'http://local.test.org'
end
