class VehicleInformation < ApplicationRecord
  resourcify

  belongs_to :vehicle
  belongs_to :vehicle_information_type
  # enum type: ['Targa','N. di telaio']

  def self.find_by_information(information,type,vehicle)
    VehicleInformation.where(information: information, vehicle_information_type: type, vehicle: vehicle).order(:date).first
  end

end
