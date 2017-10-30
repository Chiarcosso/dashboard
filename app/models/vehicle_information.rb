class VehicleInformation < ApplicationRecord
  resourcify

  belongs_to :vehicle
  belongs_to :vehicle_information_type
  # enum type: ['Targa','N. di telaio']
  
end
