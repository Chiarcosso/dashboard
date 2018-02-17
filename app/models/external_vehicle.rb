class ExternalVehicle < ApplicationRecord
  resourcify

  belongs_to :owner, class_name: 'Company'
  belongs_to :vehicle_type
  belongs_to :vehicle_typology
  
end
