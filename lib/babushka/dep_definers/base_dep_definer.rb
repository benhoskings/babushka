module Babushka
  class BaseDepDefiner < DepDefiner

    accepts_list_for :desc
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

    def on platform, method_and_block = [], &block
      unless block.nil?
        on_applicable platform, &block
      else
        method_name, block_arg = *method_and_block

        unless payload[method_name].nil?
          unless payload[method_name][:unassigned] == block_arg
            raise "You can't pass the :on option to ##{method_name} when you're using it within #on."
          end
          payload[method_name].delete(:unassigned)
        end
        block = block_arg

        send method_name, {:on => platform}, &block
      end
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
