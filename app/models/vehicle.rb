class Vehicle < ApplicationRecord
  resourcify

  # def self.carwash_codes
  #   ['N/D', 'Trattore standard', 'Motrice scarrabile', 'Autocarro cassone aperto (tre assi)', 'Autocarro cassone chiuso (tre assi)', 'Autocarro speciale', 'Semirimorchio cassone aperto (con e senza sponde idrauliche)', 'Semirimorchio cassone chiuso permanente (centinato - walking floor)', 'Semirimorchio / rimorchio cisterna', 'Rimorchio cassone aperto', 'Rimorchio cassone chiuso permanente (centinato)', 'Rimorchio trasporto mezzi / scarrabile', 'Rimorchio / semirimorchio speciale', 'Auto / furgone']
  # end
  enum carwash_code: ['N/D', 'Trattore standard', 'Motrice scarrabile', 'Autocarro cassone aperto (tre assi)', 'Autocarro cassone chiuso (tre assi)', 'Autocarro speciale', 'Semirimorchio cassone aperto (con e senza sponde idrauliche)', 'Semirimorchio cassone chiuso permanente (centinato - walking floor)', 'Semirimorchio / rimorchio cisterna', 'Rimorchio cassone aperto', 'Rimorchio cassone chiuso permanente (centinato)', 'Rimorchio trasporto mezzi / scarrabile', 'Rimorchio / semirimorchio speciale', 'Auto / furgone']

  belongs_to :model, class_name: 'VehicleModel'
  belongs_to :vehicle_typology
  belongs_to :vehicle_type

  has_many :carwash_usages_as_first, :foreign_key => 'vehicle_1_id', :class_name => 'CarwashUsage'
  has_many :carwash_usages_as_second, :foreign_key => 'vehicle_2_id', :class_name => 'CarwashUsage'

  has_many :vehicle_vehicle_equipments
  has_many :vehicle_equipments, through: :vehicle_vehicle_equipments
  has_many :vehicle_informations, :dependent => :destroy
  has_many :worksheets
  has_one :carwash_vehicle_code, :dependent => :destroy
  # has_many :carwash_usages, through: :carwash_vehicle_code
  # has_one :vehicle_type, through: :model
  belongs_to :property, class_name: 'Company'

  # scope :order_by_plate, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.vehicle_information_type_id': VehicleInformationType.plate.id) }

  scope :find_by_plate, ->(plate) { joins(:vehicle_informations).order('vehicle_informations.information ASC, vehicle_informations.date desc').where('vehicle_informations.vehicle_information_type': VehicleInformationType.plate.id).where('vehicle_informations.information LIKE ?','%'+plate+'%') }
  scope :order_by_chassis, -> { joins(:vehicle_informations).order('vehicle_informations.information ASC').where('vehicle_informations.vehicle_information_type': VehicleInformationType.chassis.id) }
  scope :find_by_chassis, ->(chassis) { joins(:vehicle_informations).order('vehicle_informations.information ASC, date desc').where('vehicle_informations.vehicle_information_type': VehicleInformationType.chassis.id).where('vehicle_informations.information LIKE ?','%'+chassis+'%') }
  scope :find_by_manufacturer, ->(manufacturer) { joins(:model).joins('vehicle_models.manufacturer').where('companies.name LIKE ?', '%'+manufacturer+'%') }
  scope :filter_by_model, ->(search) { joins(:model).where('vehicle_models.name LIKE ?', '%'+search+'%') }
  scope :filter_by_property, ->(property) { joins(:property).where('companies.name LIKE ?', '%'+property+'%') }
  scope :null_scope, -> { where(id: nil) }
  # scope :filter, ->(search) { joins(:vehicle_informations).joins(:model).joins('left join vehicle_types on vehicle_types.id = vehicles.vehicle_type_id').joins('left join vehicle_typologies on vehicle_typologies.id = vehicles.vehicle_typology_id').joins('inner join companies on vehicle_models.manufacturer_id = companies.id').joins('inner join companies prop on vehicles.property_id = prop.id').where("vehicle_informations.information LIKE '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_models.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or companies.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or prop.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_types.name LIKE '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_typologies.name LIKE '%#{search.tr(' ','%').tr('*','%')}%'").distinct }
  scope :filter, ->(search) { joins("left join vehicle_informations on vehicle_informations.vehicle_id = vehicles.id").where("vehicle_type_id in (select id from vehicle_types where name like '%#{search.tr(' ','%').tr('*','%')}%') or vehicle_typology_id in (select id from vehicle_typologies where name like '%#{search.tr(' ','%').tr('*','%')}%') or property_id in (select id from companies where name like '%#{search.tr(' ','%').tr('*','%')}%') or model_id in (select id from vehicle_models where name like '%#{search.tr(' ','%').tr('*','%')}%' or manufacturer_id in (select id from companies where name like '%#{search.tr(' ','%').tr('*','%')}%')) or vehicle_informations.information like '%#{search.tr(' ','%').tr('*','%')}%' or vehicles.id in (select vehicle_id from vehicle_vehicle_equipments inner join vehicle_equipments on vehicle_vehicle_equipments.vehicle_equipment_id = vehicle_equipments.id where vehicle_equipments.name like '%#{search.tr(' ','%').tr('*','%')}%')") }
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

  def possible_information_types
    self.vehicle_typology.vehicle_information_types + self.vehicle_type.vehicle_information_types
  end

  def last_washing
    self.carwash_usages.sort_by { |cwu| cwu.starting_time }.reverse.first unless self.carwash_usages.empty?
  end

  def carwash_usages
    self.carwash_usages_as_first + self.carwash_usages_as_second
  end

  def just_washed?
    unless self.last_washing.nil? or self.last_washing.starting_time + 3.hours < DateTime.now
      true
    else
      false
    end
  end

  def find_information(type)
    p = self.vehicle_informations.where(:vehicle_information_type => type.id).order(created_at: :desc).limit(1).first
    if p.nil?
      ''
    else
      p.information.upcase
    end
  end

  def plate
    p = self.vehicle_informations.where(:vehicle_information_type => VehicleInformationType.plate).order(date: :desc).limit(1).first
    if p.nil?
      ''
    else
      p.information.upcase
    end
  end

  def last_information(information_type)
    VehicleInformation.where(vehicle: self).where(vehicle_information_type: information_type).order(:date).last
  end

  def chassis_number
    c = self.vehicle_informations.where(:vehicle_information_type => VehicleInformationType.chassis).order(date: :desc).limit(1).first
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
