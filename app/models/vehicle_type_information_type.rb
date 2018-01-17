class VehicleTypeInformationType < ApplicationRecord
  belongs_to :vehicle_type
  belongs_to :vehicle_information_type
end
