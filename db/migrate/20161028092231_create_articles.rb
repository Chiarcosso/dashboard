class CreateArticles < ActiveRecord::Migration[5.0]
  def change
    create_table :articles do |t|
      t.string :barcode
      t.string :manufacturerCode
      t.string :name
      t.text :description
      t.integer :containedAmount
      t.integer :minimalReserve
      t.string :positionCode

      t.timestamps
    end
  end
end
