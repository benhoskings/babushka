class BaseDepDefiner
  def chooser
    :osx # hardcode this for testing
  end
end

def setup_test_lambdas
  @lambda_hello = L{ "hello world!" }
end

def test_accepts_block_for_response accepter_name, lambda, value, opts = nil
  DepDefiner.accepts_block_for accepter_name
  dep 'accepts_block_for' do
    if opts.nil?
      send accepter_name, &lambda
    else
      send accepter_name, opts, &lambda
    end
  end
  Dep('accepts_block_for').definer.send(accepter_name).should == value
end

def make_test_deps
  dep 'build tools' do
    requires {
      osx 'xcode tools'
      linux ['build-essential', 'autoconf']
    }
  end
end
