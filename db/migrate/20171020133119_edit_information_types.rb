class EditInformationTypes < ActiveRecord::Migration[5.0]
  def change
    add_reference(:vehicle_informations, :vehicle_information_type, index: true, foreign_key: true, null: false, default: 1)
    VehicleInformation.all.each do |i|
      i.update(vehicle_information_type: VehicleInformationType.find(i.information_type+1))
    end
    remove_column(:vehicle_informations, :information_type)
  end
end
