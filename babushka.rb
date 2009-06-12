require 'monkey_patches'
require 'dep'
require 'fakeistrano'

Dir.glob('deps/**/*.rb').each {|f| require f }

Dir.chdir RAILS_ROOT
Dep('migrated db').meet
