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

  def duration_label(comparison_date,seconds = true)
    string = "#{self.duration(comparison_date)/3600}:#{((self.duration(comparison_date)%3600)/60).to_s.rjust(2,'0')}"
    if seconds
      string += ":#{(((self.duration(comparison_date)%3600)%60)).to_s.rjust(2,'0')}"
    end
    string
  end

  def complete_duration_label
    if self.from.strftime("%Y-%m-%d") == self.to.strftime("%Y-%m-%d")
      "Dalle #{self.from.strftime("%H:%M")} alle #{self.to.strftime("%H:%M")}"
    else
      "Dal #{self.from.strftime("%d/%m/%Y")} al #{self.to.strftime("%d/%m/%Y")}"
    end
  end

  def self.upsync_all

    leaves = MssqlReference.query({table: 'permessi'},'chiarcosso_test')
    leaves.each do |l|
      begin
        person = Person.find_by_reference(l['persona_id'])
        next if person.nil?
        leave_code = LeaveCode.find_or_create_by_mssql_reference(l['codice_id'])
        from_time = Time.strptime("#{l['da'].strftime("%Y-%m-%d %H:%M:%S")} #{PresenceController.actual_timezone(l['da'])}","%Y-%m-%d %H:%M:%S %Z")
        to_time = Time.strptime("#{l['a'].strftime("%Y-%m-%d %H:%M:%S")} #{PresenceController.actual_timezone(l['a'])}","%Y-%m-%d %H:%M:%S %Z")
        
        if GrantedLeave.find_by(person: person, leave_code: leave_code, from: from_time, to: to_time).nil?
          if l['da'].strftime('%Y-%m-%d') == l['a'].strftime('%Y-%m-%d')
            date = Date.strptime(l['da'].strftime('%Y-%m-%d'),"%Y-%m-%d")
          end
          GrantedLeave.create(person: person, leave_code: leave_code, from: from_time, to: to_time, date: date)
        end
      rescue Exception => e
        byebug
      end
    end

  end
end
