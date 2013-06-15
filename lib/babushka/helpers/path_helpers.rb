module Babushka
  module PathHelpers
    # Make these helpers directly callable, and private when included.
    module_function

    def cd dir, opts = {}, &block
      if dir.nil?
        yield Dir.pwd.p
      else
        path = dir.p
        ShellHelpers.shell("mkdir -p '#{path}'", :sudo => opts[:sudo]) if opts[:create] unless path.exists?
        if Dir.pwd == path
          yield path
        else
          Dir.chdir path do
            LogHelpers.debug "in dir #{dir} (#{path})" do
              yield path
            end
          end
        end
      end
    end

    def in_build_dir path = '', &block
      cd Babushka::BUILD_PREFIX / path, :create => true, &block
    end

    def in_download_dir path = '', &block
      cd Babushka::DOWNLOAD_PREFIX / path, :create => true, &block
    end
  end
end
