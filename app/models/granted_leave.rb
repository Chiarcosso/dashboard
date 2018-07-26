class GrantedLeave < ApplicationRecord

  belongs_to :leave_code
  belongs_to :person

  def duration(comparison_date)

    #if the comparison date is between the leave dates
    if comparison_date.strftime("%Y-%m-%d") >= self.from.strftime("%Y-%m-%d") && comparison_date.strftime("%Y-%m-%d") <= self.to.strftime("%Y-%m-%d")

      #if is less than a day
      if self.from.strftime("%Y-%m-%d") == self.to.strftime("%Y-%m-%d")
        return (self.to - self.from).to_i
      else

        #if we compare with the leave's starting date
        if self.from.strftime("%Y-%m-%d") == comparison_date.strftime("%Y-%m-%d")
          ws = WorkingSchedule.get_schedule(self.from,self.person)
          return 0 if ws.nil?
          starting_time = Time.strptime("#{self.from.strftime("%Y-%m-%d")} #{self.from.strftime("%H:%M:%S")}","%Y-%m-%d %H:%M:%S")
          ending_time = Time.strptime("#{self.from.strftime("%Y-%m-%d")} #{ws.contract_to.strftime("%H:%M:%S")}","%Y-%m-%d %H:%M:%S")

        #if we compare with the leave's ending date
        elsif self.to.strftime("%Y-%m-%d") == comparison_date.strftime("%Y-%m-%d")
          ws = WorkingSchedule.get_schedule(self.to,self.person)
          return 0 if ws.nil?
          starting_time = Time.strptime("#{self.to.strftime("%Y-%m-%d")} #{ws.contract_from.strftime("%H:%M:%S")}","%Y-%m-%d %H:%M:%S")
          ending_time = Time.strptime("#{self.to.strftime("%Y-%m-%d")} #{self.to.strftime("%H:%M:%S")}","%Y-%m-%d %H:%M:%S")

        #if we compare in between the leave
        else
          ws = WorkingSchedule.get_schedule(comparison_date,self.person)
          return ws.nil? ? 0 : ws.contract_duration.to_i
        end

        return (ending_time - starting_time).to_i - ws.break.minutes
      end
    else
      0
    end
  end

  def duration_label(comparison_date)
    "#{self.duration(comparison_date)/3600}:#{((self.duration(comparison_date)%3600)/60).to_s.rjust(2,'0')}:#{(((self.duration(comparison_date)%3600)%60)).to_s.rjust(2,'0')}"
  end
end
