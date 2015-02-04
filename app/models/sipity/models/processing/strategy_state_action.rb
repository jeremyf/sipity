module Sipity
  module Models
    module Processing
      # An actor can take the given action
      class StrategyStateAction < ActiveRecord::Base
        self.table_name = 'sipity_processing_strategy_state_actions'
        belongs_to :originating_strategy_state, class_name: 'StrategyState'
        belongs_to :strategy_event
        has_many :strategy_state_action_permissions, dependent: :destroy
      end
    end
  end
end
