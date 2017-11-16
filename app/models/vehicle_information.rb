class VehicleInformation < ApplicationRecord
  resourcify

  belongs_to :vehicle
  belongs_to :vehicle_information_type
  # enum type: ['Targa','N. di telaio']

  def self.oldest(type,vehicle)
    VehicleInformation.where(vehicle_information_type: type, vehicle: vehicle).order(date: :asc).first
  end

  def self.latest(type,vehicle)
    VehicleInformation.where(vehicle_information_type: type, vehicle: vehicle).order(date: :desc).first
  end

  def self.find_by_information(information,type,vehicle)
    VehicleInformation.where(information: information, vehicle_information_type: type, vehicle: vehicle).order(:date).first
  end

end
