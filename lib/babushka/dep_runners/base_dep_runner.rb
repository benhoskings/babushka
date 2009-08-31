module Babushka
  class BaseDepRunner < DepRunner

    private

    def dmg url, &block
      download url
      output = shell "hdiutil attach #{File.basename url}"
      unless output.nil?
        path = output.val_for(/^\/dev\/disk\d+s\d+\s+Apple_HFS\s+/)
        returning yield path do
          shell "hdiutil detach #{path}"
        end
      end
    end

    def source url, &block
      in_build_dir {
        output = get_source url
        unless output.nil?
          in_build_dir output do |path|
            yield path
          end
        end
      }
    end

    def git url, &block
      in_build_dir {
        shell "git clone #{url}" and
        in_build_dir(File.basename(url)) {|path|
          yield path
        }
      }
    end

  end
end
