require 'fileutils'

module Babushka
  module PathHelpers
    def in_dir dir, opts = {}, &block
      if dir.nil?
        yield Dir.pwd.p
      else
        path = dir.p
        shell("mkdir '#{path}'", :sudo => opts[:sudo]) if opts[:create] unless path.exists?
        if Dir.pwd == path
          yield path
        else
          Dir.chdir path do
            debug "in dir #{dir} (#{path})" do
              yield path
            end
          end
        end
      end
    end

    def in_build_dir path = '', &block
      # TODO This shouldn't be here forever
      # Rename ~/.babushka/src to ~/.babushka/build
      if (Babushka::WorkingPrefix / 'src').p.exists? && !Babushka::BuildPrefix.p.exists?
        shell "mv ~/.babushka/src ~/.babushka/build"
      end
      in_dir Babushka::BuildPrefix / path, :create => true, &block
    end

    def in_download_dir path = '', &block
      in_dir Babushka::DownloadPrefix / path, :create => true, &block
    end
  end
end
