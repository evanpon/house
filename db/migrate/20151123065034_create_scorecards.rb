class CreateScorecards < ActiveRecord::Migration
  def change
    create_table :scorecards do |t|
      t.integer :home_id, index: true
      t.integer :kitchen, default: 0
      t.integer :light, default: 0
      t.integer :yard, default: 0
      t.integer :location, default: 0
      t.integer :potential, default: 0
      t.integer :layout, default: 0
      t.integer :charm, default: 0
      t.timestamps null: false
    end
  end
end
