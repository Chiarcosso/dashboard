class VehicleType < ApplicationRecord
  resourcify

  has_many :vehicle_models

  def to_s
    self.name
  end

end
