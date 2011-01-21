require 'spec_helper'

shared_examples_for 'renderable' do
  it "should not exist" do
    subject.exists?.should be_false
  end
  describe '#render' do
    before { subject.render(source_file) }
    it "should exist" do
      subject.exists?.should be_true
    end
    it "should have added the prefix" do
      (dest_file).read.should =~ Renderable::SEAL_REGEXP
    end
    it "should have interpolated the erb" do
      (dest_file).read.should =~ content
    end
    describe "#clean?" do
      it "should be clean" do
        subject.should be_clean
      end
      context "after shitting up the file" do
        before {
          shell "echo lulz >> #{subject.path}"
        }
        it "should not be clean" do
          subject.should_not be_clean
        end
      end
    end
    describe '#from?' do
      it "should be from the same content" do
        subject.should be_from(source_file)
      end
      it "should not be from different content" do
        subject.should_not be_from('spec/renderable/different_example.conf.erb')
      end
    end
  end
end

describe Renderable do
  context "with a config file" do
    let(:source_file) { "spec/renderable/example.conf.erb" }
    let(:dest_file) { tmp_prefix / 'example.conf' }
    let(:content) { %r{root #{tmp_prefix};} }
    subject { Renderable.new(dest_file) }
    it_should_behave_like 'renderable'
  end
  context "with a script containing a shebang" do
    let(:source_file) { "spec/renderable/example.sh" }
    let(:dest_file) { tmp_prefix / 'example.sh' }
    let(:content) { %r{babushka 'benhoskings:ready for update.deploy_repo'} }
    subject { Renderable.new(dest_file) }
    it_should_behave_like 'renderable'
  end
  describe "binding handling" do
    subject { Renderable.new(tmp_prefix / 'example.conf') }
    context "when no explicit binding is passed" do
      before {
        subject.instance_eval {
          def custom_renderable_path
            "from implicit binding"
          end
        }
        subject.render('spec/renderable/with_binding.conf.erb')
      }
      it "should render using the implicit binding" do
        (tmp_prefix / 'example.conf').read.should =~ /from implicit binding/
      end
    end
    context "when an explicit binding is passed" do
      before {
        dep 'renderable binding spec' do
          def custom_renderable_path
            "from explicit binding"
          end
        end
        subject.render('spec/renderable/with_binding.conf.erb', :context => Dep('renderable binding spec').context)
      }
      it "should render using the given binding" do
        (tmp_prefix / 'example.conf').read.should =~ /from explicit binding/
      end
    end
  end
end
