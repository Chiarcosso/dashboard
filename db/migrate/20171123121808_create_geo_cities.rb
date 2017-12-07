class CreateGeoCities < ActiveRecord::Migration[5.0]
  def change
    create_table :geo_cities do |t|
      t.string :name, null: false, index: true
      t.references :geo_province, foreign_key: true

      t.timestamps
    end
  end
end
