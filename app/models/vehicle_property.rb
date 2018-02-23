class VehicleProperty < ApplicationRecord
  resourcify
  belongs_to :vehicle
  belongs_to :owner, polymorphic:true
end
