class CreateHomes < ActiveRecord::Migration
  def change
    create_table :homes do |t|
      t.string :address
      t.integer :listing_id
      t.string :price
      t.integer :ranking

      t.timestamps null: false
    end
  end
end
