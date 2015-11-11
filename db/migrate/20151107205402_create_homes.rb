class CreateHomes < ActiveRecord::Migration
  def change
    create_table :homes do |t|
      t.string :address
      t.integer :listing_id
      t.string :price
      t.string :notes, limit: 2000
      t.integer :ranking
      
      t.timestamps null: false
    end
    add_index(:homes, :ranking)
    add_index(:homes, :listing_id, :unique => true)
  end
end
