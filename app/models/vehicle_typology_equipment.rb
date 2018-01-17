class VehicleTypologyEquipment < ApplicationRecord
  belongs_to :vehicle_typology
  belongs_to :vehicle_equipment
end
