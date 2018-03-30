class VehicleCheckSession < ApplicationRecord
  resourcify
  belongs_to :operator, class_name: Person
  belongs_to :worksheet
  belongs_to :vehicle
  belongs_to :external_vehicle

  def actual_vehicle
    if self.vehicle.nil?
      self.external_vehicle
    else
      self.vehicle
    end
  end

  def expected_time
    nil
  end

  def real_time
    nil
  end

end
