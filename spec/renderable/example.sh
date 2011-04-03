#!/bin/bash

cd .. # up from .git/
unset GIT_DIR # otherwise `git` commands can't see other repos
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # so we run against the right ruby
babushka 'benhoskings:up to date.repo' repo_path='.' git_ref_data="$(cat /dev/stdin)"
