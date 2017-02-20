class CreateOutputOrderItems < ActiveRecord::Migration[5.0]
  def change
    # drop_table :output_order_items
    create_table :output_order_items do |t|
      t.references :item
      t.references :output_order

      t.timestamps
    end
  end
end
