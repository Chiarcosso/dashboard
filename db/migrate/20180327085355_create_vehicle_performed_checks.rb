class CreateVehiclePerformedChecks < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_performed_checks do |t|
      t.references :vehicle_check_session, foreign_key: true, null: false, index: true
      t.references :vehicle_check, foreign_key: true, null: false
      t.float :value
      t.string :notes
      t.boolean :performed, null: false, default: false

      t.timestamps
    end
    if table_exists? :performed_vehicle_checks
      drop_table :performed_vehicle_checks
    end
  end
end
