class CreateOutputOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :output_orders do |t|
      t.references :createdBy, foreign_key: {to_table: :users}
      t.references :destination, polymorphic: true, null: false

      t.timestamps
    end
  end
end
