class VehicleModel < ApplicationRecord
  resourcify
  has_many :vehicles

  enum type: ['Motrice', 'Trattore', 'Rimorchio', 'Semirimorchio', 'Minivan', 'Automobile', 'Furgone', 'Ciclomotore']
  
end
