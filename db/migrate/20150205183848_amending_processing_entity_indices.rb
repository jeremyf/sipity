class AmendingProcessingEntityIndices < ActiveRecord::Migration
  def change
    # These were once unique true
    remove_index :sipity_processing_entities, :strategy_id
    remove_index :sipity_processing_entities, :strategy_state_id

    add_index :sipity_processing_entities, :strategy_id
    add_index :sipity_processing_entities, :strategy_state_id
  end
end
