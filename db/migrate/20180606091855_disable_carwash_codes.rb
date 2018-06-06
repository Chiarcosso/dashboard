class DisableCarwashCodes < ActiveRecord::Migration[5.0]
  def change
    add_column :carwash_driver_codes, :disabled, :boolean, null: false, default: false, index: true
    add_index :carwash_driver_codes, :disabled
    add_column :carwash_vehicle_codes, :disabled, :boolean, null: false, default: false, index: true
    add_index :carwash_vehicle_codes, :disabled
    add_column :carwash_special_codes, :disabled, :boolean, null: false, default: false, index: true
    add_index :carwash_special_codes, :disabled
  end
end
