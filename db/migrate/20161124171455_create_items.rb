class CreateItems < ActiveRecord::Migration[5.0]
  def change
    create_table :items do |t|
      t.date :purchaseDate
      t.decimal :price, precision: 9, scale: 2
      t.decimal :discount, precision: 5, scale: 2
      t.string :serial
      t.integer :state, limit: 3 # 0 new, 1 used, 2 regenerated, 3 refactored etc.
      t.text :notes
      t.date :expiringDate, null: true

      t.timestamps
    end
  end
end
