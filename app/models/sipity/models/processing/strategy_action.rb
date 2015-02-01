module Sipity
  module Models
    module Processing
      # A named action that, during the processing of an entity, may be taken.
      class StrategyAction < ActiveRecord::Base
        self.table_name = 'sipity_processing_strategy_actions'
        belongs_to :strategy
        has_many :strategy_events, dependent: :destroy
        has_many(:guarding_strategy_action_prerequisites,
          dependent: :destroy,
          foreign_key: :required_strategy_action_id,
          class_name: 'StrategyActionPrerequisite'
        )
        has_many(:requiring_strategy_action_prerequisites,
          dependent: :destroy,
          foreign_key: :guarded_strategy_action_id,
          class_name: 'StrategyActionPrerequisite'
        )
        has_many :guards_these_strategy_actions, through: :guarding_strategy_action_prerequisites
        has_many :requires_these_strategy_actions, through: :requiring_strategy_action_prerequisites
      end
    end
  end
end
