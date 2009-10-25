module Babushka
  module GitHelpers

    def git uri, opts = {}, &block
      repo = opts[:dir] || build_path_for(uri)
      in_dir opts[:prefix] || SrcPrefix, :create => true do
        update_success = if File.directory? repo / '.git'
          in_dir(repo) { log_shell "Updating from #{uri}", %Q{git pull origin master} }
        else
          log_shell "Cloning from #{uri}", %Q{git clone "#{uri}" "./#{repo}"}
        end

        if update_success
          block.nil? || in_dir(repo) {|path| block.call path }
        end
      end
    end

  end
end
