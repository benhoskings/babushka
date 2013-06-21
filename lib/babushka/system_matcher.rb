module Babushka
  class SystemMatcher
    attr_reader :system, :flavour, :name, :pkg_helper_key

    def initialize system, flavour, name, pkg_helper_key
      @system, @flavour, @name, @pkg_helper_key = system, flavour, name, pkg_helper_key
    end

    def list
      [name, flavour, pkg_helper_key, system, :all].compact
    end

    def matches? specs
      # TODO: shouldn't this just be:
      # (list & [*specs]).any?
      [*specs].any? {|spec| first_nonmatch_for(spec).nil? }
    end

    def differentiator_for specs
      [*specs].map {|spec|
        first_nonmatch_for spec
      }.sort_by {|spec|
        [:system, :flavour, :name].index spec
      }.compact.last
    end

    private

    def first_nonmatch_for spec
      if spec == :all
        nil
      elsif SystemDefinition.all_systems.include? spec
        spec == system ? nil : :system
      elsif PkgHelper.all_manager_keys.include? spec
        spec == pkg_helper_key ? nil : :pkg_helper
      elsif our_flavours.include? spec
        spec == flavour ? nil : :flavour
      elsif our_flavour_names.include? spec
        spec == name ? nil : :name
      else
        :system
      end
    end

    def our_flavours
      SystemDefinition::NAMES[system].keys
    end

    def our_flavour_names
      SystemDefinition::NAMES[system][flavour].values
    end
  end
end
