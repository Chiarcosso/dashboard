class VehiclePerformedCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check
  belongs_to :user

  enum fixvalues: ['Seleziona','Ok','Aggiustato','Non ok marginale','Non ok grave','Non ok bloccante']

  def self.last_reading

  end

  def vehicle
    self.vehicle_check_session.vehicle.nil?? self.vehicle_check_session.external_vehicle : self.vehicle_check_session.vehicle
  end

  def status_style
    'background: #f99' if self.mandatory
    'background: #9f9' if self.performed
  end

  def last_reading
    v = VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks where vehicle_check_session_id in (select id from vehicle_check_sessions where "+(self.vehicle.class == Vehicle ? "(vehicle_id = #{self.vehicle_check_session.vehicle.id} and vehicle_id is not null)" : "(external_vehicle_id = #{self.vehicle_check_session.external_vehicle.id} and external_vehicle_id is not null)")+") and vehicle_check_id = #{self.vehicle_check.id} and vehicle_performed_checks.id != #{self.id} order by time desc limit 1")
    v.first unless v.nil?
  end
end
