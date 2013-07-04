module Babushka
  class CurrentRuby

    def path
      @path ||= Babushka::ShellHelpers.which('ruby').p
    end

    def rbenv?
      path.to_s[%r{\brbenv/}]
    end

    def rvm?
      path.to_s[%r{\brvm/}]
    end

    def bin_dir
      # The directory in which the binaries from gems are found. This is
      # sometimes different to where `gem` itself is running from.
      gem_env['EXECUTABLE DIRECTORY'].p
    end

    def gem_dir
      gem_env['INSTALLATION DIRECTORY'] / 'gems'
    end

    def gemspec_dir
      gem_env['INSTALLATION DIRECTORY'] / 'specifications'
    end

    def version
      @_version ||= Babushka::ShellHelpers.shell('ruby --version').scan(/^ruby (\S+)/).flatten.first.to_version
    end

    def gem_version
      gem_env['RUBYGEMS VERSION'].to_version
    end

    private

    require 'yaml'
    def gem_env
      @gem_env ||= YAML.load(
        Babushka::ShellHelpers.shell('gem env').gsub(/\n  - /, "\n    ")
      )['RubyGems Environment']
    end
  end
end
