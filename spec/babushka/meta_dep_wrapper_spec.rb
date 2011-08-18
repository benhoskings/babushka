require 'spec_helper'

describe "name checks" do
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
  describe "duplicate declaration" do
    before { meta 'duplicate' }
    it "should be prevented" do
      L{ meta(:duplicate) }.should raise_error(ArgumentError, "A template called 'duplicate' has already been defined.")
    end
    after { Base.sources.anonymous.templates.clear! }
  end
end
