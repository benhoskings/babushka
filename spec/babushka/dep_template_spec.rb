require 'spec_helper'

RSpec.describe "name checks" do
  describe "invalid names" do
    it "should not allow blank names" do
      expect(L{ meta(nil) }).to raise_error(ArgumentError, "You can't define a template with a blank name.")
      expect(L{ meta('') }).to raise_error(ArgumentError, "You can't define a template with a blank name.")
    end
    it "should not allow reserved names" do
      expect(L{ meta(:base) }).to raise_error(ArgumentError, "You can't use 'base' for a template name, because it's reserved.")
    end
    it "should allow valid names" do
      expect(L{ meta(:a) }).not_to raise_error
      expect(L{ meta('b') }).not_to raise_error
      expect(L{ meta('valid') }).not_to raise_error
    end
    it "should not allow spaces and numbers" do
      expect(L{ meta('meta dep 2') }).to raise_error(ArgumentError, "You can't use 'meta dep 2' for a template name - it can only contain [a-z0-9_].")
    end
    it "should not allow invalid characters" do
      expect(L{ meta("meta\ndep") }).to raise_error(ArgumentError, "You can't use 'meta\ndep' for a template name - it can only contain [a-z0-9_].")
    end
    it "should not allow names that don't start with a letter" do
      expect(L{ meta('3d_dep') }).to raise_error(ArgumentError, "You can't use '3d_dep' for a template name - it must start with a letter.")
    end
  end

  describe "duplicates" do
    before { meta 'duplicate' }
    it "should be prevented" do
      expect(L{ meta(:duplicate) }).to raise_error(ArgumentError, "A template called 'duplicate' has already been defined.")
    end
    after { Babushka::Base.sources.anonymous.templates.clear! }
  end

  describe "valid names" do
    it "should work" do
      expect(L{ meta 'count_test' }).to change(Babushka::Base.sources.anonymous.templates, :count).by(1)
    end
    it "should downcase the name" do
      expect(meta("Case_Test").name).to eq('case_test')
    end
  end
end

RSpec.describe "declaration" do
  let(:template) { meta 'test' }
  it "should set the name" do
    expect(template.name).to eq('test')
  end
  it "should set the source" do
    expect(template.source).to eq(Babushka::Base.sources.anonymous)
  end
  it "should define a dep context" do
    expect(template.context_class).to be_an_instance_of(Class)
    expect(template.context_class.ancestors).to include(Babushka::DepContext)
  end
  it "should define template on the context" do
    expect(template.context_class.source_template).to eq(template)
  end
  it "should not define a dep helper" do
    expect(Object.new).not_to respond_to('test')
  end
  after { Babushka::Base.sources.anonymous.templates.clear! }
end

RSpec.describe "using" do
  describe "invalid template names" do
    it "should be rejected when passed as options" do
      expect(L{
        dep('something undefined', :template => 'undefined').template
      }).to raise_error(Babushka::TemplateNotFound, "There is no template named 'undefined' to define 'something undefined' against.")
    end
    it "should be ignored when passed as suffixes" do
      expect(dep('something.undefined').tap(&:template)).to be_an_instance_of(Babushka::Dep)
    end
  end

  describe "without template" do
    let!(:template) { meta('templateless_test') {} }
    it "should define deps based on the template" do
      expect(dep('templateless dep.templateless_test').template).to eq(template)
    end
    after { Babushka::Base.sources.anonymous.templates.clear! }
  end

  describe "with template" do
    let!(:template) {
      meta 'template_test' do
        def a_helper_method
          'hello from the helper!'
        end
        template {
          def a_helper
            'hello from the helper in the template!'
          end
          met? {
            'this dep is met.'
          }
        }
      end
    }
    it "should define the helper on the context class" do
      expect(template.context_class.respond_to?(:a_helper)).to be_falsey
      expect(template.context_class.new(nil).respond_to?(:a_helper)).to be_falsey
      expect(dep('dep1.template_test').context.define!.respond_to?(:a_helper)).to be_truthy
    end
    it "should correctly define the helper method" do
      expect(dep('dep2.template_test').context.a_helper_method).to eq('hello from the helper!')
    end
    it "should correctly define the helper" do
      expect(dep('dep2.template_test').context.define!.a_helper).to eq('hello from the helper in the template!')
    end
    it "should correctly define the met? block" do
      expect(dep('dep3.template_test').send(:invoke, :met?)).to eq('this dep is met.')
    end
    it "should override the template correctly" do
      expect(dep('dep4.template_test') {
        met? { 'overridden met? block.' }
      }.send(:invoke, :met?)).to eq('overridden met? block.')
    end
    after { Babushka::Base.sources.anonymous.templates.clear! }
  end

  describe "acceptors" do
    let!(:template) {
      meta 'acceptor_test' do
        accepts_list_for :list_test
        accepts_block_for :block_test
        template {
          met? {
            list_test == ['valid']
          }
          meet {
            block_test.call
          }
        }
      end
    }
    it "should handle accepts_list_for" do
      expect(dep('unmet accepts_list_for.acceptor_test') { list_test 'invalid' }.met?).to be_falsey
      expect(dep('met accepts_list_for.acceptor_test') { list_test 'valid' }.met?).to be_truthy
    end
    it "should handle accepts_block_for" do
      block_called = false
      dep('accepts_block_for.acceptor_test') {
        list_test 'invalid'
        block_test {
          block_called = true
        }
      }.meet
      expect(block_called).to be_truthy
    end
    after { Babushka::Base.sources.anonymous.templates.clear! }
  end

  describe "calling accepted blocks" do
    let(:a_meta) {
      meta :acceptor_calling_test do
        accepts_block_for(:testing) {
          self
        }
      end
    }
    let(:a_dep) {
      dep 'acceptor calling test', :template => a_meta.name
    }

    it "should run the default block in the dep's context" do
      expect(a_dep.context.invoke(:testing)).to eq(a_dep.context)
    end
  end
end
