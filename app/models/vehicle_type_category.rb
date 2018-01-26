class VehicleTypeCategory < ApplicationRecord
  belongs_to :vehicle_type
  belongs_to :vehicle_category
end
