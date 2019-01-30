class CarwashCodesDetion < ActiveRecord::Migration[5.0]
  def change
    add_column :carwash_vehicle_codes, :deleted, :boolean, null: false, default: false
    add_column :carwash_driver_codes, :deleted, :boolean, null: false, default: false
    add_column :carwash_special_codes, :deleted, :boolean, null: false, default: false
  end
end
