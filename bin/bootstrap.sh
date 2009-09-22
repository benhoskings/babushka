#!/bin/bash

from="http://github.com/benhoskings/babushka/tarball/stable"
to="$HOME/.babushka/temporary_bootstrap_install"

function true_with { echo "$1"; true; }
function false_with { echo "$1"; false; }

function check {
  if [ ! -x "`which ruby`" ] && [ ! -x "`which apt-get`" ]; then
    echo "Sorry, you don't have ruby installed, and I only know how to install it for you"
    false_with "on apt-based systems."
  elif [ ! -x "`which curl`" ] && [ ! -x "`which wget`" ]; then
    false_with "Sorry, you need either curl or wget installed before I can download."
  else
    true
  fi
}

function welcome {
  echo ""
  echo ".       .           .   .      "
  echo "|-. ,-. |-. . . ,-. |-. | , ,-."
  echo "| | ,-| | | | | \`-. | | |<  ,-|"
  echo "^-' \`-^ ^-' \`-^ \`-' ' ' ' \` \`-^"
  echo ""
  echo "So let's get down to business - First, downloading a temporary babushka from"
  echo "GitHub. Then, using it to properly install itself with all the trimmings."
  echo ""
  if [ -x "`which ruby`" ]; then
    echo "You already have ruby `ruby --version | awk '{print $2}'`, so you're all set."
  else
    echo "You don't have ruby installed, so we'll take care of that first (using apt)."
  fi
  echo ""
  read -p "Sound good? [y/N] " -n 1 f
  [[ "$f" == y* ]]
}

function install_ruby_if_required {
  if [ -x "`which ruby`" ]; then
    true # already installed
  else
    echo "First we need to install ruby (via apt)."
    sudo apt-get install -qqy ruby irb
    if [ ! -x "`which ruby`" ]; then
      false_with "Argh, the ruby install failed."
    else
      true_with "Nice, ruby `ruby --version | awk '{print $2}'` was installed at `which ruby`."
    fi
  fi
}

function create_install_dir {
  rm -rf "$to"
  mkdir -p "$to" &&
  cd "$to"
}

function stream_tarball {
  if [ -x "`which curl`" ]; then
    curl -L -\# "$from" | tar -zxf - --strip-components 1
  elif [ -x "`which wget`" ]; then
    wget --progress=bar "$from" -O - | tar -zxf - --strip-components 1
  fi
}

function handle_install {
  echo ""
  ruby "$to/bin/babushka.rb" 'babushka'
  if [ $? -eq 0 ]; then
    echo ""
    echo "All installed! If you're new, the basic idea is 'babushka <dep name>'."
    echo ""
    echo "Some top-level deps you might want to try:"
    echo "  'system', 'user setup', 'rails app', 'webserver running'"
    echo "Also, check out 'babushka --help' for usage info and some examples."
    true
  else
    echo ""
    echo "Something went wrong during the install."
    echo "There's a full log in ~/.babushka/logs/babushka. Would you mind"
    echo "emailing it to ben@hoskings.net to help improve the installation"
    echo "process? Thanks a lot."
    false
  fi
}

if check; then
  if welcome; then
    echo " -> Excellent."
    echo ""
    install_ruby_if_required && create_install_dir && stream_tarball && handle_install
  else
    echo ""
    echo "OK, maybe another time. :)"
  fi
fi
