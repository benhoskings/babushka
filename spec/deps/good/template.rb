meta :test_template do
  accepts_list_for :uri
  template {
    requires 'test dep 1'
  }
end

dep 'option-templated dep', :template => 'test_template' do
  uri 'http://option.test.org'
end

dep 'suffix-templated dep.test_template' do
  uri 'http://suffix.test.org'
end
