class AddFieldsToOrders < ActiveRecord::Migration[5.0]
  def change
    add_reference(:orders, :supplier, foreign_key: {to_table: :companies})
    add_reference(:orders, :created_by, foreign_key: {to_table: :users})
    add_reference(:articles, :created_by, foreign_key: {to_table: :users})
  end
end
