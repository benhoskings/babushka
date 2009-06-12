RAILS_ROOT = '/Users/ben/projects/babushka/testapp'
RAILS_ENV = 'production'

def appname
  'testapp'
end

def dbname
  'testapp'
end

def rails_gem_version
  $1 if File.read("#{RAILS_ROOT}/config/environment.rb") =~ /^[^#]*RAILS_GEM_VERSION\s*=\s*['"]([!~<>=]*\s*[\d.]+)['"]/
end
