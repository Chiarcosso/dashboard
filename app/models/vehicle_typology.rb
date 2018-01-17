class VehicleTypology < ApplicationRecord
  resourcify

  has_many :vehicle_type_typologies, :dependent => :destroy
  has_many :vehicle_types, through: :vehicle_type_typologies

  has_many :vehicle_typology_equipments, :dependent => :destroy
  has_many :vehicle_equipments, through: :vehicle_typology_equipments

  has_many :vehicle_typology_information_types, :dependent => :destroy
  has_many :vehicle_information_types, through: :vehicle_typology_information_types

  def self.not_available
    VehicleTypology.where(:name => 'N/D').first
  end

  def to_s
    self.name
  end

end
