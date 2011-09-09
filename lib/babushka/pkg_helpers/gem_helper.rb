module Babushka
  class GemHelper < PkgHelper
  class << self
    def pkg_type; :gem end
    def pkg_cmd; 'gem' end
    def manager_key; :gem end
    def manager_dep; 'rubygems' end

    def _install! pkgs, opts
      pkgs.each {|pkg|
        log_shell "Installing #{pkg} via #{manager_key}",
          "#{pkg_cmd} install #{cmdline_spec_for pkg} #{opts}",
          :sudo => should_sudo?
      }
    end

    def gem_path_for gem_name, version = nil
      unless (detected_version = has?(VersionOf(gem_name, version), :log => false)).nil?
        gem_root / VersionOf(gem_name, detected_version)
      end
    end

    def bin_path
      # The directory in which the binaries from gems are found. This is
      # sometimes different to where `gem` itself is running from.
      env_info.val_for('EXECUTABLE DIRECTORY').p
    end

    def gem_root
      gemdir / 'gems'
    end

    def gemspec_dir
      gemdir / 'specifications'
    end

    def gemdir
      env_info.val_for('INSTALLATION DIRECTORY')
    end

    def ruby_path
      env_info.val_for('RUBY EXECUTABLE').p
    end

    def ruby_wrapper_path
      if ruby_path.to_s['/.rvm/rubies/'].nil?
        ruby_path
      else
        ruby_path.sub(
          # /Users/ben/.rvm/rubies/ruby-1.9.2-p0/bin/ruby
          /^(.*)\/\.rvm\/rubies\/([^\/]+)\/bin\/ruby/
        ) {
          # /Users/ben/.rvm/wrappers/ruby-1.9.2-p0/ruby
          "#{$1}/.rvm/wrappers/#{$2}/ruby"
        }
      end
    end

    def ruby_arch
      if RUBY_PLATFORM =~ /universal/
        "universal"
      elsif RUBY_PLATFORM == "java"
        "java"
      elsif RUBY_PLATFORM =~ /darwin/
        # e.g. "/opt/ruby-enterprise/bin/ruby: Mach-O 64-bit executable x86_64"
        shell("file -L '#{ruby_path}'").sub(/.* /, '')
      else
        Base.host.cpu_type
      end
    end

    def ruby_binary_slug
      [
        (defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'),
        RUBY_VERSION,
        ruby_arch,
        (RUBY_PLATFORM['darwin'] ? 'macosx' : RUBY_PLATFORM.sub(/^.*?-/, ''))
      ].join('-')
    end

    def slug_for ruby
      shell %Q{#{ruby} -e "require '#{Babushka::Path.lib / 'babushka'}'; puts Babushka::GemHelper.ruby_binary_slug"}
    end

    def should_sudo?
      super || (gem_root.exists? && !gem_root.writable?)
    end

    def version
      env_info.val_for('RUBYGEMS VERSION').to_version
    end


    private

    def _has? pkg
      versions_of(pkg).sort.reverse.detect {|version| pkg.matches? version }
    end

    def versions_of pkg
      pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg
      gemspecs_for(pkg_name).select {|i|
        i.p.read.val_for('s.name')[/^[\'\"\%qQ\{]*#{pkg_name}[\'\"\}]*$/]
      }.map {|i|
        File.basename(i).scan(/^#{pkg_name}-(.*).gemspec$/).flatten.first
      }.map {|i|
        i.to_version
      }.sort
    end

    def gemspecs_for pkg_name
      gemspec_dir.glob("#{pkg_name}-*.gemspec")
    end

    def env_info
      @_cached_env_info ||= shell('gem env')
    end
  end
  end
end
