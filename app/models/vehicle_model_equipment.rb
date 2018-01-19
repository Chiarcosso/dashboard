class VehicleModelEquipment < ApplicationRecord
  belongs_to :vehicle_model
  belongs_to :vehicle_equipment
end
