class VehicleTypologyCategory < ApplicationRecord
  belongs_to :vehicle_typology
  belongs_to :vehicle_category
end
