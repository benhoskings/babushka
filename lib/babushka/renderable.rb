module Babushka
  class Renderable
    include RunHelpers

    attr_reader :path
    def initialize path
      @path = path
    end

    def render source, opts = {}
      shell("cat > '#{path}'",
        :input => inkan_output_for(source),
        :sudo => opts[:sudo]
      ).tap {|result|
        if result
          sudo "chmod #{opts[:perms]} '#{path}'" if opts[:perms]
        end
      }
    end

    def clean?
      Inkan.legitimate? path
    end

    def from? source
      source_sha == sha_of(source)
    end

    private

    def inkan_output_for source
      Inkan.render {|inkan|
        inkan.credit = "Generated #{_by_babushka}, from #{sha_of(source)}"
        inkan.print render_erb(source)
      }
    end

    def render_erb source
      ERB.new(IO.read(source)).result(binding)
    end

    require 'digest/sha1'
    def sha_of source
      Digest::SHA1.hexdigest(source.p.read)
    end

    def source_sha
      File.open(path.p) {|f|
        f.gets
      }.scan(/, from ([0-9a-f]{40})\./).flatten.first
    end
  end
end
