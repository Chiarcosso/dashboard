class CreateVehicleCheckSessions < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_check_sessions do |t|
      t.integer :theoretical_km
      t.integer :real_km, null: false
      t.date :date, null: false
      t.references :operator, foreign_key: { to_table: :people }, null: false
      t.integer :theoretical_duration, null: false
      t.integer :real_duration, null: false
      t.references :worksheet, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
