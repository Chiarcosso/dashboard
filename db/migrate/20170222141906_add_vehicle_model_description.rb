class AddVehicleModelDescription < ActiveRecord::Migration[5.0]
  def change
    change_table :vehicle_models do |t|
      t.text :description
    end
  end
end
