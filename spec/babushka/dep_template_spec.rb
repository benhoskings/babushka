require 'spec_helper'

describe "name checks" do
  describe "invalid names" do
    it "should not allow blank names" do
      L{ meta(nil) }.should raise_error(ArgumentError, "You can't define a template with a blank name.")
      L{ meta('') }.should raise_error(ArgumentError, "You can't define a template with a blank name.")
    end
    it "should not allow reserved names" do
      L{ meta(:base) }.should raise_error(ArgumentError, "You can't use 'base' for a template name, because it's reserved.")
    end
    it "should allow valid names" do
      L{ meta(:a) }.should_not raise_error
      L{ meta('b') }.should_not raise_error
      L{ meta('valid') }.should_not raise_error
    end
    it "should not allow spaces and numbers" do
      L{ meta('meta dep 2') }.should raise_error(ArgumentError, "You can't use 'meta dep 2' for a template name - it can only contain [a-z0-9_].")
    end
    it "should not allow invalid characters" do
      L{ meta("meta\ndep") }.should raise_error(ArgumentError, "You can't use 'meta\ndep' for a template name - it can only contain [a-z0-9_].")
    end
    it "should not allow names that don't start with a letter" do
      L{ meta('3d_dep') }.should raise_error(ArgumentError, "You can't use '3d_dep' for a template name - it must start with a letter.")
    end
  end

  describe "duplicates" do
    before { meta 'duplicate' }
    it "should be prevented" do
      L{ meta(:duplicate) }.should raise_error(ArgumentError, "A template called 'duplicate' has already been defined.")
    end
    after { Base.sources.anonymous.templates.clear! }
  end

  describe "valid names" do
    it "should work" do
      L{ meta 'count_test' }.should change(Base.sources.anonymous.templates, :count).by(1)
    end
    it "should downcase the name" do
      meta("Case_Test").name.should == 'case_test'
    end
  end
end

describe "declaration" do
  let(:template) { meta 'test' }
  it "should set the name" do
    template.name.should == 'test'
  end
  it "should set the source" do
    template.source.should == Base.sources.anonymous
  end
  it "should define a dep context" do
    template.context_class.should be_an_instance_of(Class)
    template.context_class.ancestors.should include(Babushka::DepContext)
  end
  it "should define template on the context" do
    template.context_class.source_template.should == template
  end
  it "should not define a dep helper" do
    Object.new.should_not respond_to('test')
  end
  after { Base.sources.anonymous.templates.clear! }
end

describe "using" do
  describe "invalid template names" do
    it "should be rejected when passed as options" do
      L{
        dep('something undefined', :template => 'undefined').template
      }.should raise_error(TemplateNotFound, "There is no template named 'undefined' to define 'something undefined' against.")
    end
    it "should be ignored when passed as suffixes" do
      dep('something.undefined').tap(&:template).should be_an_instance_of(Dep)
    end
  end

  describe "without template" do
    let!(:template) { meta('templateless_test') {} }
    it "should define deps based on the template" do
      dep('templateless dep.templateless_test').template.should == template
    end
    after { Base.sources.anonymous.templates.clear! }
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
      template.context_class.respond_to?(:a_helper).should be_false
      template.context_class.new(nil).respond_to?(:a_helper).should be_false
      dep('dep1.template_test').context.define!.respond_to?(:a_helper).should be_true
    end
    it "should correctly define the helper method" do
      dep('dep2.template_test').context.a_helper_method.should == 'hello from the helper!'
    end
    it "should correctly define the helper" do
      dep('dep2.template_test').context.define!.a_helper.should == 'hello from the helper in the template!'
    end
    it "should correctly define the met? block" do
      dep('dep3.template_test').send(:invoke, :met?).should == 'this dep is met.'
    end
    it "should override the template correctly" do
      dep('dep4.template_test') {
        met? { 'overridden met? block.' }
      }.send(:invoke, :met?).should == 'overridden met? block.'
    end
    after { Base.sources.anonymous.templates.clear! }
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
      dep('unmet accepts_list_for.acceptor_test') { list_test 'invalid' }.met?.should be_false
      dep('met accepts_list_for.acceptor_test') { list_test 'valid' }.met?.should be_true
    end
    it "should handle accepts_block_for" do
      block_called = false
      dep('accepts_block_for.acceptor_test') {
        list_test 'invalid'
        block_test {
          block_called = true
        }
      }.meet
      block_called.should be_true
    end
    after { Base.sources.anonymous.templates.clear! }
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
      a_dep.context.invoke(:testing).should == a_dep.context
    end
  end
end
