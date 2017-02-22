class VehicleInformation < ApplicationRecord
  resourcify

  belongs_to :vehicle

  enum type: ['Targa','N. di telaio']
end
