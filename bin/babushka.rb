#!/usr/bin/env ruby

# This file is what gets run when babushka is invoked from the command line.

# First, load babushka itself, by traversing from the actual location of
# this file (it might have been invoked via a symlink in the PATH) to the
# corresponding lib/babushka.rb.
require File.expand_path(
  File.join(
    File.dirname(File.expand_path(
      File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    )),
    '../lib/babushka'
  )
)

# Mix in the #Dep, #dep & #meta top-level helper methods, since we're running
# standalone.
Object.send :include, Babushka::DSL

# Handle ctrl-c gracefully during babushka runs.
Babushka::Base.exit_on_interrupt!

# Invoke babushka, returning the correct exit status to the shell.
exit !!Babushka::Base.run
