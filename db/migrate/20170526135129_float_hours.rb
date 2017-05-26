class FloatHours < ActiveRecord::Migration[5.0]
  def change
    change_column :worksheets, :hours, :decimal, precision: 4, scale: 1, null: false, default: 0
  end
end
