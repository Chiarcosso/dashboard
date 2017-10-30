class CreateVehicleVehicleEquipments < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_vehicle_equipments do |t|
      t.references :vehicle, foreign_key: true, null: false
      t.references :vehicle_equipment, foreign_key: true, null: false

      t.timestamps
    end
  end
end
