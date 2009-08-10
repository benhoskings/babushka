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

  end
end
