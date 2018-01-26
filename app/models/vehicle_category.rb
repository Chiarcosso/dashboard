class VehicleCategory < ApplicationRecord
  resourcify
  after_destroy do  |vehicle_type|
    logger.info( "VehicleType #{vehicle_type.id} #{vehicle_type.name} was destroyed by ." )
    # vehicle_type.clear_dependents
  end

  has_many :vehicles

  has_many :vehicle_model_categories, dependent: :destroy
  has_many :vehicle_models, through: :vehicle_model_categories

  has_many :vehicle_type_categories, dependent: :destroy
  has_many :vehicle_types, through: :vehicle_type_categories

  has_many :vehicle_typology_categories, dependent: :destroy
  has_many :vehicle_typologies, through: :vehicle_typology_categories

  # has_many :vehicle_type_equipments, dependent: :destroy
  # has_many :vehicle_equipments, through: :vehicle_type_equipments
  #
  # has_many :vehicle_type_information_types, dependent: :destroy
  # has_many :vehicle_information_types, through: :vehicle_type_information_types

  def self.not_available
    VehicleCategory.where(:name => 'N/D').first
  end

  def to_s
    self.name
  end
end
