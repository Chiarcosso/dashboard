class VehicleModelCategory < ApplicationRecord
  belongs_to :vehicle_model
  belongs_to :vehicle_category
end
