class CreateVehicleModelEquipments < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_model_equipments do |t|
      t.references :vehicle_model, foreign_key: true, null: false, index: true
      t.references :vehicle_equipment, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
