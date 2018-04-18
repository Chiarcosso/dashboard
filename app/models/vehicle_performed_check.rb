class VehiclePerformedCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check

  def self.last_reading

  end

  def mandatory_style
    'background: #f99' if self.mandatory
  end

  def last_reading
    # VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks where vehicle_check_session_id in (select id from vehicle_check_sessions where (vehicle_id = #{self.vehicle.id} and vehicle_id is not null) or (external_vehicle_id = #{self.external_vehicle.id} and external_vehicle_id is not null)) group by vehicle_check_id ")
    nil
  end
end
