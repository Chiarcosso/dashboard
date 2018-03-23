class VehicleCheck < ApplicationRecord
  belongs_to :vehicle
  belongs_to :vehicle_type
  belongs_to :vehicle_typology
end
