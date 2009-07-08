module Babushka
  class PkgDepDefiner < BaseDepDefiner

    accepts_hash_for :installs, :name
    accepts_hash_for :provides, :name


    def process
      super

      requires pkg_manager.manager_dep
      met? {
        if !applicable?
          log_ok "Not required on #{pkg_manager.manager_key}-based systems."
        else
          packages_present and cmds_in_path
        end
      }
      meet { install_packages }
    end


    private

    def applicable?
      !(payload[:installs].is_a?(Hash) && payload[:installs][pkg_manager.manager_key].blank?)
    end

    def packages_present
      if pkg_or_default.is_a? Hash
        pkg_or_default.all? {|pkg_name, version| pkg_manager.has?(pkg_name, :version => version) }
      else
        pkg_or_default.all? {|pkg_name| pkg_manager.has?(pkg_name) }
      end
    end

    def cmds_in_path
      present, missing = provides_or_default.partition {|cmd_name| cmd_dir(cmd_name) }
      good, bad = present.partition {|cmd_name| pkg_manager.cmd_in_path? cmd_name }

      log_ok "#{good.map {|i| "'#{i}'" }.to_list} run#{'s' if good.length == 1} from #{cmd_dir(good.first)}." unless good.empty?
      log_error "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing from your PATH." unless missing.empty?

      unless bad.empty?
        log_error "#{bad.map {|i| "'#{i}'" }.to_list} incorrectly run#{'s' if bad.length == 1} from #{cmd_dir(bad.first)}."
        log "You need to put #{pkg_manager.prefix} before #{cmd_dir(bad.first)} in your PATH."
      end

      missing.empty? and bad.empty?
    end

    def install_packages
      pkg_manager.install! pkg_or_default
    end

    def pkg_manager
      PkgManager.for_system
    end

    def pkg_or_default
      if payload[:installs].nil?
        @dep.name
      elsif payload[:installs].is_a? Hash
        payload[:installs][pkg_manager.manager_key] || []
      else
        [*payload[:installs]]
      end
    end
    def provides_or_default
      provides_for_system || [@dep.name]
    end
  end
end
