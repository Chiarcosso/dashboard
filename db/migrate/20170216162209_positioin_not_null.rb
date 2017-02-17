class PositioinNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column :items, :position_code_id, :integer, null: false
  end
end
