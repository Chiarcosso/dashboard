class ExternalVehiclesToCarwashCodes < ActiveRecord::Migration[5.0]
  def change
    add_reference :carwash_vehicle_codes, :external_vehicles, foreign_key: true
    change_column :carwash_vehicle_codes, :vehicle_id, :integer, null: true
  end
end
