class CreateSipityModelsProcessingActors < ActiveRecord::Migration
  def change
    create_table :sipity_processing_actors do |t|
      t.integer :proxy_for_id, null: false
      t.string :proxy_for_type, null: false

      t.timestamps null: false
    end

    add_index :sipity_processing_actors, [:proxy_for_id, :proxy_for_type], unique: true,
      name: :sipity_processing_actors_proxy_for
  end
end
