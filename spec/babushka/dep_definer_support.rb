class TestDepContext < DepContext
  def chooser
    :osx # hardcode this for testing
  end
end
class TestTemplate
  def self.contextual_name; name end
  def self.context_class; TestDepContext end
end
class FakeOSXSystemProfile < OSXSystemProfile
  def version; '10.6.7' end
  def get_version_info; '' end
  def total_memory; 16_000_000_000 end
end

def setup_test_lambdas
  @lambda_hello = L{ "hello world!" }
end

def test_accepts_block_for_response accepter_name, lambda, value, opts = {}
  TestDepContext.accepts_block_for accepter_name
  dep 'accepts_block_for' do
    send accepter_name, opts, &lambda
  end
  on = opts[:on].nil? ? :all : Babushka.host.system
  Dep('accepts_block_for').context.define!.payload[accepter_name][on].should == value
end

def make_test_deps
  dep 'test build tools' do
    requires {
      on :osx, 'xcode tools'
      on :linux, 'build-essential', 'autoconf'
    }
  end
end
