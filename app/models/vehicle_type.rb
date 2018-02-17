class VehicleType < ApplicationRecord
  resourcify
  after_destroy do  |vehicle_type|
    logger.info( "VehicleType #{vehicle_type.id} #{vehicle_type.name} was destroyed by ." )
    # vehicle_type.clear_dependents
  end

  has_many :vehicles

  has_many :vehicle_model_types, dependent: :destroy
  has_many :vehicle_models, through: :vehicle_model_types

  has_many :vehicle_type_categories, dependent: :destroy
  has_many :vehicle_categories, through: :vehicle_type_categories

  has_many :vehicle_type_typologies, dependent: :destroy
  has_many :vehicle_typologies, through: :vehicle_type_typologies

  has_many :vehicle_type_equipments, dependent: :destroy
  has_many :vehicle_equipments, through: :vehicle_type_equipments

  has_many :vehicle_type_information_types, dependent: :destroy
  has_many :vehicle_information_types, through: :vehicle_type_information_types

  scope :most_used, -> { where("id in "\
    "(select a.property_id from "\
      "(select property_id, count(vehicles.id) as count "\
        "from vehicles group by property_id order by count(vehicles.id) desc) as a )") }

  def self.not_available
    VehicleType.where(:name => 'N/D').first
  end

  def to_s
    self.name
  end


end
