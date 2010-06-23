def make_test_pkgs pkg_type
  dep "default #{pkg_type}", :template => pkg_type
  dep "default provides", :template => pkg_type do
    installs "something else"
  end
  dep "default installs", :template => pkg_type do
    provides "something_else"
  end
  dep "empty provides", :template => pkg_type do
    provides []
  end
end
