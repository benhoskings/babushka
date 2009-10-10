module Babushka
  class BaseDepDefiner < DepDefiner

    accepts_list_for :requires
    accepts_block_for :internal_setup
    accepts_block_for :setup
    accepts_block_for :met?
    accepts_block_for :meet
    accepts_block_for :before
    accepts_block_for :after

    def pkg_manager
      BaseHelper
    end

    def on platform, data = nil
      method_name, lambda = *data
      unless payload[method_name].nil?
        raise "You can't pass the :on option to ##{method_name} when you're using it within #on." unless payload[method_name][:unassigned] == lambda
        payload[method_name].delete(:unassigned)
      end
      store_block_for method_name, [{:on => platform}], lambda
    end

    private

    def chooser
      host.match_list
    end

    def chooser_choices
      host.all_tokens
    end

  end
end
