class CreateOutputOrderItems < ActiveRecord::Migration[5.0]
  def change
    create_table :output_order_items do |t|
      t.references :output_order, foreign_key: true, null: false
      t.references :item, foreign_key: true, null: false

      t.timestamps
    end
  end
end
