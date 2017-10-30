class VehicleTypology < ApplicationRecord
  resourcify

  def self.not_available
    VehicleTypology.where(:name => 'N/D').first
  end

  def to_s
    self.name
  end

end
