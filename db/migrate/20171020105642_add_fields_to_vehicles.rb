class AddFieldsToVehicles < ActiveRecord::Migration[5.0]
  def change
    if VehicleType.where(:name => 'N/D').size == 0
      VehicleType.create(:name => 'N/D')
    end
    if VehicleTypology.where(:name => 'N/D').size == 0
      VehicleTypology.create(:name => 'N/D')
    end
    if VehicleModel.where(:name => 'N/D').size == 0
      VehicleModel.create(:name => 'N/D', :vehicle_type => VehicleType.not_available)
    end
    type = VehicleType.where(:name => 'N/D').first
    typology = VehicleTypology.where(:name => 'N/D').first

    add_reference(:vehicles, :vehicle_type, index: true, foreign_key: true, null: false, default: type.id)
    add_reference(:vehicles, :vehicle_typology, index: true, foreign_key: true, null: false, default: typology.id)
    add_column(:vehicles, :serie, :string, null: true)
  end
end
