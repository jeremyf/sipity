class CreateSipityCollaborators < ActiveRecord::Migration
  def change
    create_table :sipity_collaborators do |t|
      t.integer :sipity_header_id
      t.integer :sequence
      t.string :name
      t.string :role
      t.timestamps
    end

    add_index :sipity_collaborators, [:sipity_header_id, :sequence]
    change_column_null :sipity_collaborators, :sipity_header_id, false
    change_column_null :sipity_collaborators, :role, false
  end
end
