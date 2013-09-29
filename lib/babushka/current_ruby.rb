module Babushka

  # This class provides information about the active ruby installation according
  # to the system's $PATH. This might be different to the ruby via which
  # babushka was invoked.
  #
  # The preferred way to use this class is via `Babushka.ruby`.
  class CurrentRuby

    # The path the ruby binary that is visible via the $PATH.
    def path
      @path ||= Babushka::ShellHelpers.which('ruby').p
    end

    # Is the current ruby managed by rbenv?
    def rbenv?
      path.to_s[%r{\brbenv/}]
    end

    # Is the current ruby managed by rvm?
    def rvm?
      path.to_s[%r{\brvm/}]
    end

    # The directory in which the binaries from gems are found.
    #
    # This is sometimes different to where `gem` itself is running from.
    def bin_dir
      gem_env.val_for('EXECUTABLE DIRECTORY').p
    end

    # Where all the gems are actually installed
    def gem_dir
      gem_env.val_for('INSTALLATION DIRECTORY') / 'gems'
    end

    # Where all the gemspecs are saved
    def gemspec_dir
      gem_env.val_for('INSTALLATION DIRECTORY') / 'specifications'
    end

    # The ruby version
    def version
      @_version ||= Babushka::ShellHelpers.shell('ruby --version').scan(/^ruby (\S+)/).flatten.first.to_version
    end

    # The rubygems version
    def gem_version
      gem_env.val_for('RUBYGEMS VERSION').to_version
    end

    private

    def gem_env
      @_gem_env ||= Babushka::ShellHelpers.shell('gem env')
    end
  end
end
