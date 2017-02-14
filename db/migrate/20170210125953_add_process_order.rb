class AddProcessOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :output_orders, :processed, :boolean, default: false
  end
end
