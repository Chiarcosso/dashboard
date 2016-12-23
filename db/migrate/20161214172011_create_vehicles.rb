class CreateVehicles < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicles do |t|
      t.boolean :dismissed, default: false
      t.date :registration_date
      t.string :initial_serial
      t.integer :mileage

      t.timestamps
    end
    add_reference(:vehicles, :property, foreign_key: {to_table: :companies})
    add_reference(:vehicles, :model, foreign_key: {to_table: :vehicle_models})
  end
end
