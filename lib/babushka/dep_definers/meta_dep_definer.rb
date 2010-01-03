module Babushka
  class MetaDepDefiner < BaseDepDefiner

    def self.template &block
      @template = block unless block.nil?
      @template
    end

    def process
      instance_eval &self.class.template unless self.class.template.nil?
    end

  end
end
