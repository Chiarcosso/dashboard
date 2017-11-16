class VehicleInformationType < ApplicationRecord
  resourcify

  def self.plate
    VehicleInformationType.find_by_name('Targa')
  end

  def self.chassis
    VehicleInformationType.find_by_name('Numero telaio')
  end
end
