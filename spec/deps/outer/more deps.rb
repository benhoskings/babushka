meta 'another_local_template' do
  accepts_list_for :uri
end

dep 'separate file', :template => 'another_local_template' do
  uri 'http://option.local.test.org'
end

dep 'separate file.another_local_template' do
  uri 'http://suffix.local.test.org'
end
