class FixOutputOrderItems < ActiveRecord::Migration[5.0]
  def change
    add_column :output_order_items, :from_mobile_workshop, :boolean, null: false, default: false
  end
end
