class VehicleEquipment < ApplicationRecord
  resourcify

  has_many :vehicle_vehicle_equipments
  has_many :vehicles, through: :vehicle_vehicle_equipments
  
  has_many :vehicle_typology_equipments, dependent: :destroy
  has_many :vehicle_typologies, through: :vehicle_typology_equipments

  has_many :vehicle_type_equipments, dependent: :destroy
  has_many :vehicle_types, through: :vehicle_type_equipments

  def mounted_on? vehicle
    vehicle.vehicle_equipments.each do |e|
      return true if self == e
    end
    false
  end
end
