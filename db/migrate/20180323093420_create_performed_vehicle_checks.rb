class CreatePerformedVehicleChecks < ActiveRecord::Migration[5.0]
  def change
    create_table :performed_vehicle_checks do |t|
      t.references :vehicle_check_session, foreign_key: true, null: false, index: true
      t.references :vehicle_check, foreign_key: true, null: false
      t.float :value
      t.string :notes
      t.boolean :performed, null: false, default: false

      t.timestamps
    end
  end
end
