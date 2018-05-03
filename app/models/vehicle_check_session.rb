class VehicleCheckSession < ApplicationRecord
  resourcify
  belongs_to :operator, class_name: User
  belongs_to :worksheet
  belongs_to :vehicle
  belongs_to :external_vehicle
  has_many :vehicle_performed_checks, :dependent => :destroy

  scope :opened, -> { where(finished: nil) }
  scope :closed, -> { where('finished is not null').order(finished: :desc) }
  scope :last_week, -> { where("date > '#{(Date.today - 7).strftime('%Y-%m-%d')}'") }

  def actual_vehicle
    if self.vehicle.nil?
      self.external_vehicle
    else
      self.vehicle
    end
  end

  def vehicle_ordered_performed_checks
    res = Hash.new
    self.vehicle_performed_checks.sort_by{ |vc| [ vc.performed?.to_s, vc.mandatory ? 0 : 1, -vc.vehicle_check.importance, vc.vehicle_check.label ] }.each do |vpc|
      res[vpc.vehicle_check.code] = Array.new if res[vpc.vehicle_check.code].nil?
      res[vpc.vehicle_check.code] << vpc
    end
    res
    # self.vehicle_performed_checks.sort_by{ |vc| [ !vc.mandatory, !vc.performed.to_s, -vc.vehicle_check.importance, vc.vehicle_check.label ] }
    #.order({mandatory: :desc, performed: :asc, importance: :desc, label: :asc})
  end

  def destination_label
    "#{self.actual_vehicle.plate}#{self.worksheet.nil?? '' : " (ODL nr. #{self.worksheet.number}"}"
  end

  def theoretical_duration_label
    "#{(self.theoretical_duration/60).floor.to_s.rjust(2,'0')}:#{(self.theoretical_duration%60).to_s.rjust(2,'0')}"
  end

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{((self.real_duration.to_i/60)%60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
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
