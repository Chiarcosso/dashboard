class CreateVehicleInformations < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_informations do |t|
      t.references :vehicle, foreign_key: true
      t.integer :information_type
      t.string :information
      t.date :date

      t.timestamps
    end
  end
end
