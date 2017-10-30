class CreateVehicleEquipments < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_equipments do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
