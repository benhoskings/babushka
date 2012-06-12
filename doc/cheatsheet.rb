# A dep should handle just one specific task in isolation. For example, admins
# being able to sudo is really two separate jobs: "the admin group exists" and
# "the sudoers entry for admins exists".
#
# Keeping deps really small and simple makes them (a) easier to write, (b) much
# more robust, and (c) really easy for other people to re-use.

dep 'admin group' do
  # Returns a bool (i.e. "is this dep met?")
  met? { '/etc/group'.p.grep(/^admin\:/) }

  # Blindly do whatever is required to meet the dep.
  meet { shell "groupadd admin" }
end

# The dep name can be any string. Keep it nice and simple, though, because
# you have to type it on the commandline to run the dep.
dep 'admins can sudo' do
  # A list of the names of all the deps this one requires.
  requires 'admin group'

  # The met? block should never make any changes to the system. It should
  # only ever inspect the system, and return true/false.
  met? {
    # There are lots of helpers to do things like edit files, render configs.
    # Check the API for a full list.
    !sudo('cat /etc/sudoers').split("\n").grep(/^%admin/).empty?
  }

  # The meet block should never do any checks. It should just unconditionally
  # make all the changes. If you find you need to use non-trivial
  # conditionals within meet {}, it probably means you should split this dep up
  # into smaller, more focused deps.
  meet { append_to_file '%admin  ALL=(ALL) ALL', '/etc/sudoers', :sudo => true }
end


# As well as the most basic dep, with #requires, #met? and #meet, you can use
# templates to wrap up met?/meet logic and focus the DSL for whatever task you
# like.

# The 'bin' and 'lib' templates are for installing binaries and libraries via
# the system's package manager. Their logic is simple:
# - in the met? block, 'bin' checks whether its binaries are in the path, and
#   'lib' checks whether its libraries' packages are installed;
# - in the meet block, both 'bin' and 'lib' just ask PkgHelper to install the
#   appropriate packages via the system's package manager.
# You don't have to tell them what kind of system you're on because babushka
# works that out. Currently PkgHelper knows how to use homebrew (on OS X),
# apt (on Debian/Ubuntu), yum (on Fedora/CentOS), and pacman (on Arch).
dep 'wget.bin'

# To tweak the package, there are some package-specific methods you can use.

dep 'git.bin' do
  # Use 'installs' to list the packages this dep should install. You can pass
  # an array, or any number of splatted arguments.
  # It defaults to the package name - in this case, it would default to 'git'.
  installs 'git-core'
end

dep 'ruby', :template => 'bin' do
  # You can split any of these lists per-system with a block, like so:
  installs {
    via [:lenny, :hardy, :lucid], %w[ruby irb ruby1.8-dev libopenssl-ruby]
    via :apt, %w[ruby ruby1.8-dev]
    via :yum, %w[ruby ruby-irb]
    otherwise 'ruby'
  }
  # Use 'provides' to specify the executeables this package should add to the
  # PATH. Babushka checks both that the commands are available, and that they
  # all run from the same path (so, for example, you're not running
  # /usr/bin/gem against /usr/local/bin/ruby).
  provides 'ruby >= 1.8.6', 'irb'
end

# To install a library, you don't need to worry about setting 'provides', because
# a library provides no binaries. Just list the packages involved.
dep 'ncurses.lib' do
  installs {
    via :apt, 'libncurses5-dev', 'libncursesw5-dev'
    via :brew, 'ncursesw'
  }
end

# As well as the 'bin' and 'lib' templates, you can use 'gem', 'npm', and 'pip' to
# write deps that understand cross-platform package managers.

# For example, to install the image_science gem, which needs the 'freeimage'
# library and installs no commands:
dep 'image_science.gem' do
  requires 'freeimage'
  provides []
end

# You can specify specific versions using any gem version operator.
dep 'unicorn.gem' do
  # This will install the latest available unicorn-0.4 gem.
  installs 'unicorn ~> 0.4.0'
end

# Those version operators aren't just for gem versions, though -- you can use
# them on other packages, and to check versions in other situations.
dep 'postgres.bin' do
  installs 'postgresql'
  # This checks the installed version by running `psql --version` and parsing
  # the output. Most commands support --version, and this provides a
  # consistent interface to it.
  provides 'psql ~> 9.0.0'
end

# Here's an example of installing an npm package. It's much the same as the
# others -- just set #installs and #provides as required. Here we're installing
# 'juggernaut', which provides a binary of the same name.
dep 'juggernaut.npm'

# The same applies to pip too. The django pip needs to be customised though,
# because the package name and binary don't fit the convention.
dep 'django.pip' do
  installs 'Django'
  provides 'django-admin.py'
end

# You can use the '.src' template to build and install programs from source.
dep 'fish.src' do
  requires 'ncurses', 'doc', 'coreutils', 'sed'

  # Babushka will pull the source from here, and save it in ~/.babushka/src for
  # later (i.e. it only ever downloads once).
  # It can handle the following:
  # http://, https://, ftp:// - babushka downloads the URL via `curl`, and
  #   attempts to extract it if it's an archive of some sort.
  # (no protocol) - babushka assumes `curl` can handle it, as above.
  # git:// - babushka clones the URL, or if it is already cloned, does a
  #   fetch / reset to update.
  source "https://github.com/benhoskings/fish.git"

  # The 'provides' setting is just the same as in '.managed', '.gem', and
  # others - it does all the same checks, and defaults to the package name:
  # provides 'fish'
  #
  # As above though, you can use version operators to do a more specific check:
  provides 'fish >= 1.23.1'

  # For generating the --prefix configure arg; defaults to /usr/local.
  # prefix '/usr/local'

  # This is run before configure. It defauls to running autoconf, if ./configure
  # doesn't already exist and it can be generated by an .in or .ac.
  # preconfigure { shell "autoconf" }

  # Specify env vars to set for configure, to achieve e.g. KEY='val' ./configure
  configure_env "LDFLAGS='-liconv -L/opt/local/lib'" if host.osx?

  # Specify configure args, to achieve e.g. ./configure --with-feature
  configure_args "--without-xsel"

  # Do the build. Default:
  # build { shell "make" }

  # Do the install. Default:
  # install { sudo "make install" }
end
