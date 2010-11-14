module Babushka
  class Renderable
    include RunHelpers

    attr_reader :path
    def initialize path
      @path = path
    end

    def render source
      Inkan.seal(path) {|inkan|
        inkan.credit = "Generated #{_by_babushka}, from #{sha_of(source)}"
        inkan.print render_erb(source)
      }
    end

    private

    def render_erb source
      ERB.new(IO.read(source)).result(binding)
    end

    require 'digest/sha1'
    def sha_of source
      Digest::SHA1.hexdigest(source.p.read)
    end
  end
end
