require 'uri'

module Babushka
  class Resource
    extend LogHelpers
    extend ShellHelpers
    extend PathHelpers

    def self.get url, &block
      filename = URI.unescape(url.to_s).p.basename
      if filename.to_s.blank?
        log_error "Not a valid URL to download: #{url}"
      elsif url.to_s[%r{^git://}]
        GitHelpers.git(url, &block)
      else
        download_path = in_download_dir {|path|
          downloaded_file = download(url, filename)
          path / downloaded_file if downloaded_file
        }
        block.call download_path unless download_path.nil?
      end
    end

    def self.extract url, &block
      get url do |download_path|
        in_build_dir {
          Asset.for(download_path).extract(&block)
        }
      end
    end

    def self.download url, filename = url.to_s.p.basename
      if filename.p.exists? && !filename.p.empty?
        log_ok "Already downloaded #{filename}."
        filename
      else
        success = log_block "Downloading #{url}" do
          shell('curl', '-#', '-L', '-o' "#{filename}.tmp", url.to_s, :progress => /[\d\.]+%/) &&
            shell('mv', '-f', "#{filename}.tmp", filename)
        end

        filename if success
      end
    end

  end
end
