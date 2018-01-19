class VehicleModelType < ApplicationRecord
  belongs_to :vehicle_model
  belongs_to :vehicle_type
end
