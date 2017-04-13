class VehicleType < ApplicationRecord
  resourcify

  has_many :vehicle_models
  
end
