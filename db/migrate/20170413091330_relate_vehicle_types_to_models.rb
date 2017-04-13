class RelateVehicleTypesToModels < ActiveRecord::Migration[5.0]
  def change
    if VehicleType.all.size == 0
      VehicleType.create(name: 'N/D')
    end
    remove_column :vehicle_models, :vehicle_type, :integer
    add_reference(:vehicle_models, :vehicle_type, index: true, foreign_key: true, null: false, default: 1)
  end
end
