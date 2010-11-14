module Babushka
  class Renderable
    include RunHelpers

    attr_reader :source
    def initialize source
      @source = source
    end

    def render_to target
      Inkan.seal(target) {|inkan|
        inkan.credit = "Generated #{_by_babushka}"
        inkan.print render_erb
      }
    end

    private

    def render_erb
      ERB.new(IO.read(@source)).result(binding)
    end
  end
end
