class VehicleEquipment < ApplicationRecord
  resourcify

  def mounted_on? vehicle
    vehicle.vehicle_equipments.each do |e|
      return true if self == e
    end
    false
  end
end
