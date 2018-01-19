class VehicleModelInformationType < ApplicationRecord
  belongs_to :vehicle_model
  belongs_to :vehicle_information_type
end
