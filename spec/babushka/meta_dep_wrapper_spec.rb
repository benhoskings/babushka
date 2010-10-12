require 'spec_helper'

describe "name checks" do
  it "should not allow blank names" do
    L{ meta(nil) }.should raise_error(ArgumentError, "You can't define a template with a blank name.")
    L{ meta('') }.should raise_error(ArgumentError, "You can't define a template with a blank name.")
  end
  it "should not allow reserved names" do
    L{ meta(:base) }.should raise_error(ArgumentError, "You can't use 'base' for a template name, because it's reserved.")
  end
  context "option" do
    it "should allow spaces and numbers" do
      L{ meta('meta dep 2') }.should_not raise_error
    end
    it "should not allow invalid characters" do
      L{ meta("meta\ndep") }.should raise_error(ArgumentError, "You can't use 'meta\ndep' for a template name - it can only contain [a-z0-9_].")
    end
    it "should not allow names that don't start with a letter or dot" do
      L{ meta('3d_dep') }.should raise_error(ArgumentError, "You can't use '3d_dep' for a template name - it must start with a letter.")
    end
  end
  context "suffix" do
    it "should not allow invalid characters" do
      L{ meta('.meta dep') }.should raise_error(ArgumentError, "You can't use 'meta dep' for a suffixed template name - it can only contain [a-z0-9_].")
    end
    it "should not allow names that don't start with a letter or dot" do
      L{ meta('.3d_dep') }.should raise_error(ArgumentError, "You can't use '3d_dep' for a template name - it must start with a letter.")
    end
  end
  describe "duplicate declaration" do
    before { meta 'duplicate' }
    it "should be prevented" do
      L{ meta(:duplicate) }.should raise_error(ArgumentError, "A template called 'duplicate' has already been defined.")
    end
    after { Base.sources.anonymous.templates.clear! }
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
