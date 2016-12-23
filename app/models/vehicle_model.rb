class VehicleModel < ApplicationRecord
  resourcify
  has_many :vehicles
  
end
