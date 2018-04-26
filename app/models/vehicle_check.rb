class VehicleCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle
  belongs_to :vehicle_type
  belongs_to :vehicle_typology
    
  def style_by_importance
    ''
  end
end
