def setup_test_lambdas
  @lambda_hello = L{ "hello world!" }
end

def setup_test_deps
  pkg 'default'
  pkg 'default provides' do
    installs 'something else'
  end
  pkg 'default installs' do
    provides 'something_else'
  end
  pkg 'empty provides' do
    provides []
  end
end
