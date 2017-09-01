class AddCarwashCodesIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index(:carwash_driver_codes, [:code])
    add_index(:carwash_driver_codes, [:code], :unique => true)
    remove_index(:carwash_vehicle_codes, [:code])
    add_index(:carwash_vehicle_codes, [:code], :unique => true)
  end
end
