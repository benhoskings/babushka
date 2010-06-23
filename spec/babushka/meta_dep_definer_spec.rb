require 'spec_support'
require 'dep_definer_support'

describe "name checks" do
  it "should not allow blank names" do
    L{ meta(nil) }.should raise_error ArgumentError, "You can't define a template with a blank name."
    L{ meta('') }.should raise_error ArgumentError, "You can't define a template with a blank name."
  end
  it "should not allow reserved names" do
    L{ meta(:base) }.should raise_error ArgumentError, "You can't use 'base' for a template name, because it's reserved."
  end
  context "option" do
    it "should allow spaces and numbers" do
      L{ meta('meta dep 2') }.should_not raise_error
    end
    it "should not allow invalid characters" do
      L{ meta("meta\ndep") }.should raise_error ArgumentError, "You can't use 'meta\ndep' for a template name - it can only contain [a-z0-9_]."
    end
    it "should not allow names that don't start with a letter or dot" do
      L{ meta('3d_dep') }.should raise_error ArgumentError, "You can't use '3d_dep' for a template name - it must start with a letter."
    end
  end
  context "suffix" do
    it "should not allow invalid characters" do
      L{ meta('.meta dep') }.should raise_error ArgumentError, "You can't use 'meta dep' for a suffixed template name - it can only contain [a-z0-9_]."
    end
    it "should not allow names that don't start with a letter or dot" do
      L{ meta('.3d_dep') }.should raise_error ArgumentError, "You can't use '3d_dep' for a template name - it must start with a letter."
    end
  end
  describe "duplicate declaration" do
    before { meta 'duplicate' }
    it "should be prevented" do
      L{ meta(:duplicate) }.should raise_error ArgumentError, "A template called 'duplicate' has already been defined."
    end
    after { Base.sources.default.templates.clear! }
  end
end

describe "classification" do
  it "should classify templates starting with letters as option templates" do
    meta('classification option').should_not be_suffixed
  end
  it "should classify templates starting with '.' as suffix templates" do
    meta('.classification_suffix').should be_suffixed
  end
end

shared_examples_for 'defined meta dep' do
  it "should work" do
    L{
      meta 'count_test'
    }.should change(Base.sources.default.templates, :count).by(1)
  end
  it "should set the name" do
    @meta.name.should == 'test'
  end
  it "should define a dep definer" do
    @meta.definer_class.should be_an_instance_of Class
    @meta.definer_class.ancestors.should include Babushka::BaseDepDefiner
    @meta.runner_class.should_not == Babushka::BaseDepDefiner
  end
  it "should define template on the definer" do
    @meta.definer_class.source_template.should == @meta
  end
  it "should define a dep runner" do
    @meta.runner_class.should be_an_instance_of Class
    @meta.runner_class.ancestors.should include Babushka::BaseDepRunner
    @meta.runner_class.should_not == Babushka::BaseDepRunner
  end
  it "should not define a dep helper" do
    Object.new.should_not respond_to 'test'
  end
end

describe "declaration" do
  before {
    @meta = meta 'test'
  }
  it_should_behave_like 'defined meta dep'
  it "should not be marked as suffixed" do
    @meta.opts[:suffix].should be_false
  end
  after { Base.sources.default.templates.clear! }
end

describe "declaration with dot" do
  before {
    @meta = meta '.test'
  }
  it_should_behave_like 'defined meta dep'
  it "should be marked as suffixed" do
    @meta.opts[:suffix].should be_true
  end
  describe "collisions" do
    before { meta 'collision_test' }
    it "should conflict, disregarding the dot" do
      L{ meta '.collision_test' }.should raise_error ArgumentError, "A template called 'collision_test' has already been defined."
    end
  end
  after { Base.sources.default.templates.clear! }
end

describe "using" do
  describe "invalid templates" do
    it "should not define deps as options" do
      L{
        dep('something undefined', :template => 'undefined').should be_nil
      }.should raise_error DepError, "Can't find the 'undefined' template to define 'something undefined' against."
    end
    it "should define deps as options" do
      dep('something.undefined').should be_an_instance_of(Dep)
    end
  end

  describe "without template" do
    describe "the new suffix" do
      before {
        meta('templateless_test') {}
      }
      it "should be useable" do
        dep('templateless dep.templateless_test').definer.should be_an_instance_of TemplatelessTestDepDefiner
      end
    end
    after { Base.sources.default.templates.clear! }
  end

  describe "with template" do
    before {
      @meta = meta 'template_test' do
        template {
          helper :a_helper do
            'hello from the helper!'
          end
          met? {
            'this dep is met.'
          }
        }
      end
    }
    it "should define the helper on the runner class" do
      @meta.runner_class.respond_to?(:a_helper).should be_false
      @meta.runner_class.new(nil).respond_to?(:a_helper).should be_false
      dep('dep1.template_test').runner.respond_to?(:a_helper).should be_true
    end
    it "should correctly define the helper" do
      dep('dep2.template_test').runner.a_helper.should == 'hello from the helper!'
    end
    it "should correctly define the met? block" do
      dep('dep3.template_test').send(:call_task, :met?).should == 'this dep is met.'
    end
    after { Base.sources.default.templates.clear! }
  end

  describe "acceptors" do
    before {
      @meta = meta 'acceptor_test' do
        accepts_list_for :list_test
        accepts_block_for :block_test
        template {
          met? {
            list_test == [ver('valid')]
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
    after { Base.sources.default.templates.clear! }
  end
end
