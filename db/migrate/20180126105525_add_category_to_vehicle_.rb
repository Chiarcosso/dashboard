class AddCategoryToVehicle < ActiveRecord::Migration[5.0]
  remove_column :vehicles, :vehicle_category_id if column_exists? :vehicles, :vehicle_category_id
  change_table :vehicles do |t|
    t.references :vehicle_category, foreign_key: true, null: false, index:true, default: 1
  end
end
