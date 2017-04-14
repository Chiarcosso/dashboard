class Vehicle < ApplicationRecord
  resourcify

  belongs_to :model, class_name: 'VehicleModel'
  has_many :vehicle_informations
  has_many :worksheets
  has_one :vehicle_type, through: :model
  belongs_to :property, class_name: 'Company'

  scope :order_by_plate, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.information_type': VehicleInformation.types['Targa']) }
  scope :find_by_plate, ->(plate) { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.information_type': VehicleInformation.types['Targa']).where('vehicle_informations.information LIKE ?',plate) }

  self.per_page = 30

  def plate
    p = self.vehicle_informations.where(:information_type => VehicleInformation.types['Targa']).order(created_at: :desc).limit(1).first
    if p.nil?
      ''
    else
      p.information.upcase
    end
  end

  def chassis_number
    c = self.vehicle_informations.where(:information_type => VehicleInformation.types['N. di telaio']).order(created_at: :desc).limit(1).first
    if c.nil?
      ''
    else
      c.information
    end
  end

  def complete_name
    self.model.manufacturer.name+' '+self.plate
  end

end
