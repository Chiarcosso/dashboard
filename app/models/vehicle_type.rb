class VehicleType < ApplicationRecord
  resourcify

  has_many :vehicle_models

  def self.not_available
    VehicleType.where(:name => 'N/D').first
  end

  def to_s
    self.name
  end

end
