class UniqueVehicleCategories < ActiveRecord::Migration[5.0]
  def change
    add_index :vehicle_categories, :name, unique: true, name: :vehicle_categories_unique_name unless index_exists? :vehicle_categories, :name, name: :vehicle_categories_unique_name
  end
end
