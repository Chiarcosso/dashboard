class VehicleCheckSession < ApplicationRecord
  resourcify
  belongs_to :operator, class_name: Person
  belongs_to :worksheet
  belongs_to :vehicle
  belongs_to :external_vehicle
  has_many :vehicle_performed_checks

  def actual_vehicle
    if self.vehicle.nil?
      self.external_vehicle
    else
      self.vehicle
    end
  end

  def destination_label
    "#{self.actual_vehicle.plate}#{self.worksheet.nil?? '' : " (ODL nr. #{self.worksheet.number}"}"
  end

  def theoretical_duration_label
    "#{(self.theoretical_duration/60).floor.to_s.rjust(2,'0')}:#{(self.theoretical_duration%60).to_s.rjust(2,'0')}"
  end

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i/60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
  end

  def recalculate_expected_time
    self.theoretical_duration = self.actual_vehicle.vehicle_checks.map{ |c| c.duration }.inject(0,:+)
    self.save
  end

  def recalculate_real_time
    # self.real_duration = self.vehicle_performed_checks.map{ |c| c.duration }.inject(0,:+)
    # self.save
  end

end
