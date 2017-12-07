class UniqueGeoNames < ActiveRecord::Migration[5.0]
  def change
    add_column :geo_cities, :zip, :string unless column_exists? :geo_cities, :zip
    add_column :geo_localities, :zip, :string unless column_exists? :geo_localities, :zip
    add_index :languages, :name, unique: true unless index_exists? :languages, :name, unique: true
    add_index :geo_states, :name, unique: true unless index_exists? :geo_states, :name, unique: true
  end
end
