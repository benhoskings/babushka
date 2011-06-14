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

# If babushka was invoked as a command, then we run according to the arguments
# and exit. If it wasn't (i.e. it was required by an interactive session or
# another app), then the above require is all we needed to do.
exit Babushka::Base.run ? 0 : 1 if $0 == __FILE__
