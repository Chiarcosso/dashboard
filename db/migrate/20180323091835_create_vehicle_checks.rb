class CreateVehicleChecks < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_checks do |t|
      t.string :code, null: false, index: true, unique: true
      t.references :vehicle, foreign_key: true, index: true
      t.references :vehicle_type, foreign_key: true, index: true
      t.references :vehicle_typology, foreign_key: true, index: true
      t.integer :importance, null: false, index: true
      t.integer :duration, null: false
      t.boolean :check_driver, null: false, default: true, index: true
      t.boolean :check_carwash, null: false, default: true, index: true
      t.boolean :check_workshop, null: false, default: true, index: true
      t.integer :frequency_km
      t.integer :frequency_time
      t.integer :alert_before_km
      t.integer :alert_before_time
      t.boolean :both_expired, null: false, default: false
      t.boolean :generate_worksheet, null: false, default: true
      t.string :label, null: false, index: true, unique: true
      t.decimal :val_min
      t.decimal :val_max
      t.integer :group_id

      t.timestamps
    end
  end
end
