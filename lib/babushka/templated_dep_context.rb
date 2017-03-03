module Babushka
  class TemplatedDepContext < DepContext

    def self.template &block
      @template = block unless block.nil?
      @template
    end

    def self.metaclass
      class << self; self end
    end

    def define!
      instance_eval(&self.class.template) unless self.class.template.nil?
      super
    end

  end
end
