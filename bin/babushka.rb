#!/usr/bin/env ruby

# Traverse from this file (which might have been invoked via a symlink in
# the PATH) to the corresponding lib/babushka.rb.
require File.expand_path(
  File.join(
    File.dirname(File.expand_path(
      File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    )),
    '../lib/babushka'
  )
)

# Mix in the #Dep, #dep & #meta top-level helper methods, since we're running standalone.
Object.class_eval {
  include Babushka::Dep::Helpers
}

Babushka::Base.exit_on_interrupt!

# Invoke babushka, returning the correct exit status to the shell.
exit Babushka::Base.run
