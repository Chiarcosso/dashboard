class PerformedVehicleCheck < ApplicationRecord
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check
end
