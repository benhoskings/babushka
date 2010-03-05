module Babushka
  module GitHelpers

    def git uri, opts = {}, &block
      repo = opts[:dir] || File.basename(uri.to_s)
      in_dir opts[:prefix] || SrcPrefix, :create => true do
        update_success = if File.directory? repo / '.git'
          in_dir(repo) {
            log uri do
              [
                'git fetch origin',
                "git reset --hard origin/#{current_branch}"
              ].all? {|cmd|
                shell cmd do |shell|
                  returning shell.ok? do |result|
                    log result ? shell.stdout : shell.stderr
                  end
                end
              }
            end
          }
        else
          log_shell "Cloning from #{uri}", %Q{git clone "#{uri}" "#{'.' / repo}"}
        end

        returning update_success do
          FileUtils.touch repo # so we can tell when it was last updated
          block.nil? || in_dir(repo) {|path| block.call path }
        end
      end
    end

    def current_branch path = nil
      in_dir path do
        shell("git branch --no-color").lines.grep(/^\*/).first.scan(/\* (.*)/).flatten.first
      end
    end

  end
end
