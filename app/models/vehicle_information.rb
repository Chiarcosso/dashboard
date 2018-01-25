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

  def next
    unless self.date.nil?
      infos = VehicleInformation.where(vehicle_information_type: self.vehicle_information_type, vehicle: self.vehicle).where("date >= #{self.date} ").order(date: :asc).limit(2)
      if infos.size == 2
        infos[1]
      else
        nil
      end
    end
  end

  def date_to
    self.next.date unless self.next.nil?
  end

  def self.find_by_information(information,type,vehicle)
    VehicleInformation.where(information: information, vehicle_information_type: type, vehicle: vehicle).order(:date).first
  end

end
