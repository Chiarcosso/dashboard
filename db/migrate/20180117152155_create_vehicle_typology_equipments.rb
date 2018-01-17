class CreateVehicleTypologyEquipments < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_typology_equipments do |t|
      t.references :vehicle_typology, foreign_key: true, null: false, index: true
      t.references :vehicle_equipment, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
