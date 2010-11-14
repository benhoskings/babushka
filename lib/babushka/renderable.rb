module Babushka
  class Renderable
    include RunHelpers

    attr_reader :path
    def initialize path
      @path = path
    end

    def render source
      Inkan.seal(path) {|inkan|
        inkan.credit = "Generated #{_by_babushka}"
        inkan.print render_erb(source)
      }
    end

    private

    def render_erb source
      ERB.new(IO.read(source)).result(binding)
    end
  end
end
