class AddNotesToHomes < ActiveRecord::Migration
  def change
    add_column :homes, :notes, :string, limit: 2000
  end
end
