class VehicleModel < ApplicationRecord
  resourcify
  has_many :vehicles

  has_many :vehicle_model_types, dependent: :destroy
  has_many :vehicle_types, through: :vehicle_model_types

  has_many :vehicle_model_typologies, dependent: :destroy
  has_many :vehicle_typologies, through: :vehicle_model_typologies

  has_many :vehicle_model_categories, dependent: :destroy
  has_many :vehicle_categories, through: :vehicle_model_categories

  has_many :vehicle_model_equipments, dependent: :destroy
  has_many :vehicle_equipments, through: :vehicle_model_equipments

  has_many :vehicle_model_information_types, dependent: :destroy
  has_many :vehicle_information_types, through: :vehicle_model_information_types


  belongs_to :manufacturer, class_name: 'Company'

  # enum vehicle_type: ['Motrice', 'Trattore', 'Rimorchio', 'Rimorchio scarrabile', 'Semirimorchio', 'Minivan', 'Automobile', 'Furgone', 'Ciclomotore', 'Muletto']
  scope :filter, ->(search) {  includes(:manufacturer).where("companies.name like '%#{search.tr(' ','%').tr('*','%')}%' or vehicle_models.name like '%#{search.tr(' ','%').tr('*','%')}%'")}
  scope :manufacturer_model_order, -> { includes(:manufacturer).order('companies.name').order('vehicle_models.name') }
  # scope :order_by_model, -> { includes(:manufacturer).order('companies.name').order('vehicle_models.name') }

  def self.not_available
    VehicleModel.where(:name => 'N/D').first
  end

  def count
    Vehicle.where(model: self).size
  end

  def complete_name
    m = self.manufacturer.nil?? '' : self.manufacturer.name+' '
    m+self.name
  end

  def to_s
    self.complete_name
  end
end
