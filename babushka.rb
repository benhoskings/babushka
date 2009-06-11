require 'monkey_patches'
require 'dep'
require 'deps'

Dir.chdir RAILS_ROOT
Dep('migrated db').meet
