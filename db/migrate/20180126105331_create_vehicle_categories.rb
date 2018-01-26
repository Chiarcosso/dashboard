class CreateVehicleCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicle_categories do |t|
      t.string :name, null: false, index: true
      t.text :description

      t.timestamps
    end
    VehicleCategory.create(name: 'N/D',description: '')
  end
end
