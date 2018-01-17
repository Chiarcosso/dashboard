class VehicleTypeEquipment < ApplicationRecord
  belongs_to :vehicle_type
  belongs_to :vehicle_equipment
end
