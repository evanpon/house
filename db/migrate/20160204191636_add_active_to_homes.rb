class AddActiveToHomes < ActiveRecord::Migration
  def change
    add_column(:homes, :active, :boolean, default: false)
  end
end
