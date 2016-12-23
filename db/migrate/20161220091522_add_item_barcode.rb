class AddItemBarcode < ActiveRecord::Migration[5.0]
  def change
    change_table :items do |t|
      t.string :barcode, unique: true
    end
  end
end
