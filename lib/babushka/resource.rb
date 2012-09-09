module Babushka
  class Resource
    extend LogHelpers
    extend ShellHelpers
    extend PathHelpers

    def self.get url, &block
      filename = URI.unescape(url.to_s).p.basename
      if filename.to_s.blank?
        log_error "Not a valid URL to download: #{url}"
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
      elsif (result = shell(%Q{curl -I -X GET "#{url}"})).nil?
        log_error "Couldn't download #{url}: `curl` exited with non-zero status."
      else
        response_code = result.val_for(/HTTP\/1\.\d/) # not present for ftp://, etc.
        if response_code && response_code[/^[23]/].nil?
          log_error "Couldn't download #{url}: #{response_code}."
        elsif !(location = result.val_for('Location')).nil?
          log "Following redirect from #{url}"
          download URI.escape(location), location.p.basename
        else
          success = log_block "Downloading #{url}" do
            shell %Q{curl -# -o "#{filename}.tmp" "#{url}" && mv -f "#{filename}.tmp" "#{filename}"}, :progress => /[\d\.]+%/
          end
          filename if success
        end
      end
    end

  end
end
