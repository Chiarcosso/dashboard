class TimesheetRecord < ApplicationRecord
  belongs_to :person
  belongs_to :workshop_operation

  def real_minutes
    unless self.stop.nil?
      ceil((self.stop - self.start) / 60)
    end
  end

  def time_label
    # Transform minutes in 'HH:MM' format
    if self.minutes.nil?
      'Errore, operazione non conclusa.'
    else
      hrs = (self.minutes / 60).floor
      mins = self.minutes % 60
      "#{hrs.to_s.rjust(2,'0')}:#{mins.to_s.rjust(2,'0')}"
    end
  end
end
