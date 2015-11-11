class CreateDetails < ActiveRecord::Migration
  def change
    create_table :details do |t|
      t.integer :home_id
      t.string :name
      t.string :value, limit: 2000

      t.timestamps null: false
    end
    add_index(:details, [:home_id, :name], unique: true)
  end
end
