def setup_test_lambdas
  @lambda_hello = L{ "hello world!" }
end

def setup_test_deps
  dep 'default'
end
