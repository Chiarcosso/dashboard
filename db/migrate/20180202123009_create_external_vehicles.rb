class CreateExternalVehicles < ActiveRecord::Migration[5.0]
  def change
    create_table :external_vehicles do |t|
      t.integer :owner_id, foreign_key: { to_table: :companies }, index: true, null: false
      t.string :plate, index: true, null: false, unique: true
      t.integer :id_veicolo, null: false, unique: true
      t.integer :id_fornitore, null: false
      t.references :vehicle_type, foreign_key: true, index: true, null: false
      t.references :vehicle_typology, foreign_key: true, index: true, null: true

      t.timestamps
    end
  end
end
