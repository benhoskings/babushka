$:.push File.join(File.dirname(__FILE__), '..', 'lib/fancypath')

require 'fancypath'

def Fancypath path
  Fancypath.new path
end
