class AddGeoConstraints < ActiveRecord::Migration[5.0]
  def change
    add_index :geo_provinces, [:name,:geo_state_id,:code], unique: true unless index_exists? :geo_provinces, [:name,:geo_state_id,:code], unique: true
    add_index :geo_cities, [:name,:geo_province_id,:zip], unique: true unless index_exists? :geo_cities, [:name,:geo_province_id,:zip], unique: true
    add_index :geo_localities, [:name,:geo_city_id,:zip], unique: true unless index_exists? :geo_localities, [:name,:geo_city_id,:zip], unique: true
  end
end
