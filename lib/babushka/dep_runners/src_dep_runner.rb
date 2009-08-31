require 'uri'

module Babushka
  class SrcDepRunner < BaseDepRunner

    private

    def do_it_live
      download_and_extract and configure and build and install
    end

    def download_and_extract
      in_build_dir {
        get.all? {|uri| handle_source URI.parse uri.to_s }
      }
    end

    def handle_source uri
      case uri.scheme
      when 'http'
        get_source uri.to_s
      when 'git'
        git_update uri
      end
    end

    def git_update uri
      repo = File.basename uri.path
      in_build_dir {
        if File.directory? repo
          in_build_dir(repo) { log_shell "Already cloned; updating.", %Q{git pull origin master} }
        else
          log_shell "Cloning", %Q{git clone "#{uri}" "./#{repo}"}
        end
      }
    end

    def configure
      in_build_dir do
        shell "./configure --prefix=#{prefix}"
      end
    end

  end
end
