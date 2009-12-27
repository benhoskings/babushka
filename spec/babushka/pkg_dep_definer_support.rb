def make_test_pkgs pkg_type
  send pkg_type, "default #{pkg_type}"
  send pkg_type, "default provides" do
    installs "something else"
  end
  send pkg_type, "default installs" do
    provides "something_else"
  end
  send pkg_type, "empty provides" do
    provides []
  end
end
