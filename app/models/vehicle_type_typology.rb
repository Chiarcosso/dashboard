class VehicleTypeTypology < ApplicationRecord
  resourcify
  belongs_to :vehicle_type
  belongs_to :vehicle_typology

  
end
