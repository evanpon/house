class AddValueToHomes < ActiveRecord::Migration
  def change
    add_column(:homes, :value, :integer, default: 0)
    add_index(:homes, :value)
    
    remove_index(:homes, :ranking)
  end
end
