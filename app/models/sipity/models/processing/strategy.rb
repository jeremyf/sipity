module Sipity
  module Models
    module Processing
      # A named strategy for processing an entity. Originally I had thought of
      # calling this a Type, but once I extracted the Processing submodule,
      # type felt to much of a noun, not conveying potentiality. Strategy
      # conveys "things will happen" because of this.
      class Strategy < ActiveRecord::Base
        self.table_name = 'sipity_processing_strategies'

        has_many :entities, dependent: :destroy
        has_many :strategy_states, dependent: :destroy
        has_many :strategy_actions, dependent: :destroy
        has_many :strategy_roles, dependent: :destroy
        has_many :roles, through: :strategy_roles
      end
    end
  end
end
