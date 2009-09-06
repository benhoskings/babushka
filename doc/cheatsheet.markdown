# A dep should handle just one specific task in isolation. For example, admins being
# able to sudo is really two separate jobs: "the admin group exists" and "the sudoers entry
# for admins exists".
#
# Keeping deps really small and simple makes them (a) easier to write, (b) much more
# robust, and (c) really easy for other people to re-use.

dep 'admin group' do
  # Returns a bool (i.e. "is this dep met?")
  met? { grep /^admin\:/, '/etc/group' }

  # Blindly do whatever is required to meet the dep.
  meet { shell "groupadd admin" }
end

# The dep name can be any string. Keep it nice and simple, though, because
# you have to type it on the commandline to run this dep.
dep 'admins can sudo' do
  # A list of the names of all the deps this one requires.
  requires 'admin group'

  # The met? block should never make any changes to the system. It should
  # only ever inspect the system, and return true/false.
  met? {
    # There are lots of helpers to do things like edit files, render configs. Check
    # the API for a full list.
    grep /^%admin/, '/etc/sudoers'
  }

  # The meet block should never do any checks. It should just unconditionally
  # make all the changes. If you find you need to use non-trivial
  # conditionals within meet {}, it probably means you should split this dep up
  # into smaller, more focused deps.
  meet { append_to_file '%admin  ALL=(ALL) ALL', '/etc/sudoers' }
end


# As well as the most basic dep, with #requires, #met? and #meet, there are lots of specialised
# dep types for common jobs. Here are some examples.

# The 'pkg' dep knows how to use the package manager. You don't have to tell it what kind of
# system you're on because it can work that out. Currently it knows how to use apt (on Linux)
# and macports (on OS X).
pkg 'wget'

# To tweak the package, there are some pkg-specific methods you can use.

pkg 'git' do
  # Use 'installs' to list the packages this dep should install. You can pass an array, or any
  # number of splatted arguments.
  # It defaults to the pkg name - in this case, it would default to 'git'.
  installs 'git-core'
end

pkg 'ruby' do
  # You can split it any of these lists per-system with a block, like so:
  installs {
    macports 'ruby'
    apt %w[ruby irb ri rdoc ruby1.8-dev libopenssl-ruby]
  }
  # Use 'provides' to specify the executeables this package should add to the PATH. Babushka
  # checks both that the commands are available, and that they run from the correct location (i.e.
  # that the command running is the one that the package manager installed, and not some other
  # version).
  # So in this case, Babushka checks that these 4 commands run from /opt/local/bin.
  provides %w[ruby irb ri rdoc]
end

pkg 'ncurses' do
  installs {
    apt 'libncurses5-dev', 'libncursesw5-dev'
    macports 'ncurses', 'ncursesw'
  }
  # The 'provides' value defaults to the pkg name too. For libraries (like ncurses),
  # just make it an empty list:
  provides []
end

# as well as pkg{} you can use gem{} to write deps that understand rubygems. For example, to
# install the image_science gem, which needs the 'freeimage' library and installs no commands:
gem 'image_science' do
  requires 'freeimage'
  provides []
end

# You can specify specific versions using any gem version operator.
gem 'hammock' do
  # This will install the latest available hammock-0.3 gem.
  installs 'hammock' => '~> 0.3.1'
end


# You can use src{} to build and install programs from source, if they conform to the standard
# configure/make/make install build process.
src 'fish' do
  requires 'ncurses', 'doc', 'coreutils', 'sed'

  # Babushka will pull the source from here, and save it in ~/.babushka/src for later (i.e. it
  # only ever downloads once).
  # It can handle the following:
  # http:// - Babushka downloads the URL and attempts to extract it as a tarball
  # git:// - Babushka clones the URL, or if it is already cloned, does a 'git pull' to update
  source "git://github.com/benhoskings/fish.git"

  # The 'provides' setting is just the same as in pkg{} and gem{} - it performs all the
  # same checks, and defaults to the package name.
  # provides 'fish'

  # For generating the --prefix configure arg; defaults to /usr/local.
  # prefix '/usr/local'

  # This is run before configure. Defaults to nothing.
  preconfigure { shell "autoconf" }

  # Specify env vars to set for configure, to achieve e.g. KEY='val' ./configure
  configure_env "LDFLAGS='-liconv -L/opt/local/lib'" if osx?

  # Specify configure args, to achieve e.g. ./configure --with-feature
  configure_args "--without-xsel"
  
  # Do the build. Default:
  # build { shell "make" }

  # Do the install. Default:
  # build { sudo "make install" }
end
