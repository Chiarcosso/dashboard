class FixVehiclePerformedChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :vehicle_performed_checks, :is_last, :boolean, null: false, default: false
    add_reference :vehicle_performed_checks, :vehicle, null: true, foreign_key: true
    add_reference :vehicle_performed_checks, :external_vehicle, null: true, foreign_key: true
    add_index :vehicle_performed_checks, [:is_last, :vehicle_id, :vehicle_check_id], name: :vpf_vehicle_last_check
    add_index :vehicle_performed_checks, [:is_last, :external_vehicle_id, :vehicle_check_id], name: :vpf_external_vehicle_last_check
  end
end
