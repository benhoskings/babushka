def rails_gem_version
  $1 if File.read("#{RAILS_ROOT}/config/environment.rb") =~ /^[^#]*RAILS_GEM_VERSION\s*=\s*['"]([!~<>=]*\s*[\d.]+)['"]/
end
