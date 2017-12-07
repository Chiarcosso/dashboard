class CreateGeoProvinces < ActiveRecord::Migration[5.0]
  def change
    create_table :geo_provinces do |t|
      t.string :name, null: false, index: true
      t.string :code
      t.references :geo_state, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
