class Vehicle < ApplicationRecord
  resourcify

  belongs_to :model, class_name: 'VehicleModel'
  has_many :vehicle_informations

  def plate
    self.vehicle_information.where(:infromation_type => 0).order(:date).limit(1).first
  end

  def chassis_number
    self.vehicle_information.where(:infromation_type => 1).order(:date).limit(1).first
  end

  def complete_name
    self.model.manufacturer.name+' '+self.plate
  end
end
