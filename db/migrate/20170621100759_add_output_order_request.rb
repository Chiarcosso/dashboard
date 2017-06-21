class AddOutputOrderRequest < ActiveRecord::Migration[5.0]
  def change
    add_reference(:output_orders, :receiver, foreign_key: {to_table: :people}, null: true)
  end
end
