class FixItemsDiscountNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column :items, :discount, :decimal, precision: 5, scale: 2, null: false, default: 0.0
    change_column :items, :price, :decimal, precision: 9, scale: 2, null: false, default: 0.0
  end
end
