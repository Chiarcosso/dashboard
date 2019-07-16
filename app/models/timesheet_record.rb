class TimesheetRecord < ApplicationRecord
  belongs_to :person
  belongs_to :workshop_operation

  def self.close_all(person)
    TimesheetRecord.where(person: person, minutes: nil).each do |tr|
      tr.close
    end
  end

  def close
    if self.stop.nil?
      if self.workshop_operation.nil?
        time = Time.now
      else
        if self.workshop_operation.ending_time.nil?
          time = self.workshop_operation.last_stopping_time.nil? ? Time.now : self.workshop_operation.last_stopping_time
        else
          time = self.workshop_operation.ending_time
        end
      end
    else
      time = self.stop
    end
    # If the end is beyond working time use presence timestamp to close it
    unless self.get_presence_record.nil? || time < self.get_presence_record.end
      time = self.get_presence_record.end
    end
    begin
      # if start is nil something very strange happened, let's fix it for the time being
      if self.start.nil?
        if self.workshop_operation.nil? || self.workshop_operation.starting_time.nil?
          return nil
        else
          self.update(start: self.workshop_operation.starting_time)
        end
      end
      # 9 hours maximal cap
      if ((time - self.start) / 60).ceil > 60*9
        time = self.start + 9.hours
      end
      self.update(stop: time, minutes: ((time - self.start) / 60).ceil)
    rescue Exception => e
      @error = "timesheet_record.rb 43\n\n"+e.message+"\n\n\n"+e.backtrace.join("\n\n")
      ErrorMailer.error_report(@error,"Errore tempi lavorazione. id: #{self.id}").deliver_now
    end
  end

  def get_presence_record
    if self.start.nil?
      return nil
    else
      PresenceRecord.joins('inner join presence_timestamps st on st.id = presence_records.start_ts_id')
              .joins('inner join presence_timestamps et on et.id = presence_records.end_ts_id')
              .where(person: self.person)
              .where(" ? between st.time and et.time", self.start).first
    end
  end

  def real_minutes
    unless self.stop.nil?
      ((self.stop - self.start) / 60).ceil
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
