class VehicleProperty < ApplicationRecord
  resourcify
  belongs_to :vehicle
  belongs_to :owner, polymorphic:true

  def name
    owner.name
  end
end
