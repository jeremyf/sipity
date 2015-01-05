class CreateSipityAdditionalAttributes < ActiveRecord::Migration
  def change
    create_table :sipity_additional_attributes do |t|
      t.integer :sip_id, null: false
      t.string :key, null: false
      t.string :value

      t.timestamps
    end
  end
end
