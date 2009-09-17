#!/bin/bash

prefix="/usr/local"
binpath="$prefix/bin"

# The tarball
from="http://github.com/benhoskings/babushka/tarball/stable"
# Where the tarball goes
to="$prefix/babushka"

function true_with { echo "$1"; true; }
function false_with { echo "$1"; false; }

function not_already_installed {
  if [ -e "$to" ]; then
    false_with "Looks like babushka is already installed at /usr/local/babushka."
  else
    true
  fi
}
function have_ruby {
  if [ -x "`which ruby`" ]; then
    true_with "We haz a ruby."
  elif [ -x "`which port`" ]; then
    echo "First, we need to install ruby (you'll need to type your sudo password)."
    sudo apt-get install -qqy ruby
    if [ ! -x "`which ruby`" ]; then
      false_with "Argh, the ruby install failed."
    else
      true_with "We haz a ruby."
    fi
  else
    false_with "You don't have ruby installed, and I only know how to install it for you on apt-based systems."
  fi
}

function stream_tarball {
  mkdir -p "$to"
  cd "$to"
  curl -L -\# "$from" | tar -zxf - --strip-components 1
}
function link_binary {
  echo "Linking to $binpath."
  cd "$binpath"
  ln -sf "$to/bin/babushka.rb" "./babushka"
  chmod +x './babushka'
}
function report_result {
  echo ""
  if [ -x "$binpath/babushka" ]; then
    echo "Done! If you're new to babushka, check out the help:"
    true_with "$ babushka --help"
  else
    false_with "Something went wrong during the install."
  fi
}

function bootstrap_babushka {
  echo "Installing babushka to $to (via a series of tubes)."
  stream_tarball
  link_binary
  report_result
}

# Do it live.
echo "\n"
not_already_installed && have_ruby && bootstrap_babushka
