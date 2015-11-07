class CreateFields < ActiveRecord::Migration
  def change
    create_table :fields do |t|
      t.integer :home_id
      t.string :name
      t.string :value

      t.timestamps null: false
    end
  end
end
