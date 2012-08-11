def setup_test_lambdas
  @lambda_hello = L{ "hello world!" }
end

def test_accepts_block_for_response accepter_name, lambda, value, opts = {}
  DepContext.accepts_block_for accepter_name
  dep 'accepts_block_for' do
    send accepter_name, opts, &lambda
  end
  on = opts[:on].nil? ? :all : Babushka.host.system
  Dep('accepts_block_for').context.define!.payload[accepter_name][on].should == value
end
