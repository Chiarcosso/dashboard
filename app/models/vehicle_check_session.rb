class VehicleCheckSession < ApplicationRecord
  belongs_to :operator
  belongs_to :worksheet
end
