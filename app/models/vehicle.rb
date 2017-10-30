class Vehicle < ApplicationRecord
  resourcify

  belongs_to :model, class_name: 'VehicleModel'
  belongs_to :vehicle_typology
  belongs_to :vehicle_type

  has_many :vehicle_informations
  has_many :worksheets
  # has_one :vehicle_type, through: :model
  belongs_to :property, class_name: 'Company'

  scope :order_by_plate, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.vehicle_information_type_id': VehicleInformationType.where(:name => 'Targa').first.id) }
  scope :find_by_plate, ->(plate) { joins(:vehicle_informations).order('vehicle_informations.information ASC, vehicle_informations.date desc').where('vehicle_informations.vehicle_information_type': VehicleInformationType.where(:name => 'Targa').first.id).where('vehicle_informations.information LIKE ?','%'+plate+'%') }
  scope :order_by_chassis, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.vehicle_information_type': VehicleInformationType.where(:name => 'N. di telaio').first.id) }
  scope :find_by_chassis, ->(chassis) { joins(:vehicle_informations).order('vehicle_informations.information ASC, date desc').where('vehicle_informations.vehicle_information_type': VehicleInformationType.where(:name => 'N. di telaio').first.id).where('vehicle_informations.information LIKE ?','%'+chassis+'%') }
  scope :find_by_manufacturer, ->(manufacturer) { joins(:model).joins('vehicle_models.manufacturer').where('companies.name LIKE ?', '%'+manufacturer+'%') }
  scope :find_by_model, ->(search) { joins(:model).where('vehicle_models.name LIKE ?', '%'+search+'%') }
  scope :find_by_property, ->(property) { joins(:property).where('companies.name LIKE ?', '%'+property+'%') }
  scope :null_scope, -> { where(id: nil) }
  scope :filter, ->(search) { joins(:vehicle_informations).joins(:model).joins('inner join companies on vehicle_models.manufacturer_id = companies.id').where("vehicle_informations.information LIKE '%#{search}%' or vehicle_models.name LIKE '%#{search}%' or companies.name LIKE '%#{search}%'").distinct.limit(150) }
  # scope :filter, ->(search) { find_by_plate(search).or(find_by_chassis(search)).or(find_by_model(search)).or(find_by_manufacturer(search)) }

  self.per_page = 30

  # def self.find_by_manufacturer_method search
  #   Vehicle.find_by_manufacturer(search)
  # end
  #
  # def self.find_by_property_method search
  #   Vehicle.find_by_property(search)
  # end
  #
  # def self.find_by_plate_method search
  #   Vehicle.find_by_plate(search)
  # end
  #
  # def self.find_by_chassis_method search
  #   Vehicle.find_by_chassis(search)
  # end
  def find_information(type)
    p = self.vehicle_informations.where(:vehicle_information_type => type.id).order(created_at: :desc).limit(1).first
    if p.nil?
      ''
    else
      p.information.upcase
    end
  end

  def plate
    p = self.vehicle_informations.where(:vehicle_information_type => VehicleInformationType.where(:name => 'Targa').first.id).order(created_at: :desc).limit(1).first
    if p.nil?
      ''
    else
      p.information.upcase
    end
  end

  def chassis_number
    c = self.vehicle_informations.where(:vehicle_information_type => VehicleInformationType.where(:name => 'N. di telaio').first.id).order(created_at: :desc).limit(1).first
    if c.nil?
      ''
    else
      c.information
    end
  end

  def complete_name
    self.plate+' '+self.model.complete_name
  end

end
