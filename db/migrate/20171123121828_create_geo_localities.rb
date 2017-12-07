class CreateGeoLocalities < ActiveRecord::Migration[5.0]
  def change
    create_table :geo_localities do |t|
      t.string :name, null: false, index: true
      t.references :geo_city, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
