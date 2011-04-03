module Babushka
  module PathHelpers
    def cd dir, opts = {}, &block
      if dir.nil?
        yield Dir.pwd.p
      else
        path = dir.p
        shell("mkdir -p '#{path}'", :sudo => opts[:sudo]) if opts[:create] unless path.exists?
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

    def in_dir dir, opts = {}, &block
      log_error "#{caller.first}: #in_dir has been renamed to #cd." # deprecated
      cd dir, opts, &block
    end

    def in_build_dir path = '', &block
      log_error "#{caller.first}: #in_build_dir is deprecated. Instead, use cd(Babushka::BuildPrefix)." # deprecated
      cd Babushka::BuildPrefix / path, :create => true, &block
    end

    def in_download_dir path = '', &block
      log_error "#{caller.first}: #in_download_dir is deprecated. Instead, use cd(Babushka::DownloadPrefix)." # deprecated
      cd Babushka::DownloadPrefix / path, :create => true, &block
    end
  end
end
