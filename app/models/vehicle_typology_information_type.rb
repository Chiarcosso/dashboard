class VehicleTypologyInformationType < ApplicationRecord
  belongs_to :vehicle_typology
  belongs_to :vehicle_information_type
end
