class BaseDepDefiner
  def chooser
    :osx # hardcode this for testing
  end
end

def setup_test_lambdas
  @lambda_hello = L{ "hello world!" }
end

def test_accepts_block_for_response accepter_name, lambda, value, opts = {}
  DepDefiner.accepts_block_for accepter_name
  dep 'accepts_block_for' do
    send accepter_name, opts, &lambda
  end
  on = opts[:on].nil? ? :all : host.system
  Dep('accepts_block_for').definer.payload[accepter_name][on].should == value
end

def make_test_deps
  dep 'build tools' do
    requires {
      on :osx, 'xcode tools'
      on :linux, 'build-essential', 'autoconf'
    }
  end
end
