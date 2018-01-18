class VehicleInformationType < ApplicationRecord
  resourcify

  enum data_type: ['Stringa (max 255 caratteri)', 'Numero intero', 'Numero decimale', 'Data', 'Testo']

  has_many :vehicle_informations
  has_many :vehicles, through: :vehicle_informations

  has_many :vehicle_typology_information_types, dependent: :destroy
  has_many :vehicle_typologies, through: :vehicle_typology_information_types

  has_many :vehicle_type_information_types, dependent: :destroy
  has_many :vehicle_types, through: :vehicle_type_information_types

  def self.plate
    VehicleInformationType.find_by_name('Targa')
  end

  def self.chassis
    VehicleInformationType.find_by_name('Numero telaio')
  end
end
