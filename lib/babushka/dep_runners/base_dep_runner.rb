module Babushka
  class BaseDepRunner < DepRunner

    private

    def dmg url, &block
      download url
      output = shell "hdiutil attach #{File.basename url}"
      unless output.nil?
        path = output.val_for(/\/dev\/disk\d+s1\s+Apple_HFS/)
        returning yield path do
          shell "hdiutil detach #{path}"
        end
      end
    end

  end
end
