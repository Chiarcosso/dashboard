class WorkshopOperation < ApplicationRecord

  belongs_to :worksheet
  belongs_to :user
  has_one :vehicle, through: :worksheet

  scope :to_notification, ->(protocol) { where(myofficina_reference: protocol.to_i) }

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{((self.real_duration.to_i/60)%60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
  end

  def operator
    self.user.person
  end

  def ew_notification
    EurowinController::get_notification(self.myofficina_reference)
  end

  def siblings
    WorkshopOperation.where(myofficina_reference: self.myofficina_reference) - [self]
  end

  def self.exist_or_create(worksheet,sgn)
    WorkshopOperation.create(name: 'Lavorazione', myofficina_reference: sgn, worksheet: worksheet) unless WorkshopOperation.where(myofficina_reference: sgn).count > 0
  end
end
