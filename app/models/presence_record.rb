class PresenceRecord < ApplicationRecord
  belongs_to :start_ts, class_name: 'PresenceTimestamp', foreign_key: :start_ts_id
  belongs_to :end_ts, class_name: 'PresenceTimestamp', foreign_key: :end_ts_id
  belongs_to :person

  enum weekdays: ['Dom.','Lun.','Mar.','Mer.','Gio.','Ven.','Sab.']

  def self.time_on_date(date,person)
    time = PresenceRecord.where(date: date, person: person).order(set_day_time: :asc).first
    if time.nil?
      return 0
    else
      time.set_day_time
    end
  end

  def start
    self.start_ts.time
  end

  def end
    self.end_ts.time
  end

  def timesheet_records
    TimesheetRecord.where(person: self.person).where("start between ? and ?",self.start,self.end)
  end

  def check_timesheets(time = nil)
    self.timesheet_records.where("stop is null").each do |tr|
      tr.close(time)
      tr.workshop_operation.pause unless tr.workshop_operation.nil?
    end
  end

  def set_day_time_label
    "#{(self.set_day_time.to_i/3600).to_s.rjust(2,'0')}:#{((self.set_day_time.to_i%3600)/60).to_s.rjust(2,'0')}"
  end

  def self.actual_day_time_label(date,person)
    actual_total = PresenceRecord.where(date: date, person: person, break: false).map{ |pr| pr.actual_duration }.inject(0,:+)
    "#{(actual_total/3600).to_s.rjust(2,'0')}:#{((actual_total%3600)/60).to_s.rjust(2,'0')}"
  end

  def duration_label(calculated = true)
    if calculated
      "#{self.calculated_duration/3600}:#{((self.calculated_duration%3600)/60).to_s.rjust(2,'0')}:#{(((self.calculated_duration%3600)%60)).to_s.rjust(2,'0')}"
    else
      "#{self.actual_duration/3600}:#{((self.actual_duration%3600)/60).to_s.rjust(2,'0')}:#{(((self.actual_duration%3600)%60)).to_s.rjust(2,'0')}"
      # ts_start = self.start_ts.time
      # ts_end = self.end_ts.nil? ? self.start_ts.time : self.end_ts.time
      # duration = (ts_end - ts_start).to_i
      # "#{duration/3600}:#{((duration%3600)/60).to_s.rjust(2,'0')}:#{(((duration%3600)%60)).to_s.rjust(2,'0')}"
    end
  end

  def time_in_record(time = Time.now)

    if time >= self.start_ts.time && self.end_ts.nil?
      if self.start_ts.time.strftime("%Y%m%d") == time.strftime("%Y%m%d")
        true
      else
        false
      end
    else
      if time >= self.start_ts.time && time <= self.end_ts.time
        true
      else
        false
      end
    end
  end

  def self.round_delay(interval)
    delay = 15*(2**((((interval.to_i/60)-1)/15)/2))
    delay = 2 * 60 if delay > 2 * 60
    delay
  end

  def self.round_interval(interval,direction = :-)
    return interval if interval%(30*60) == 0
    if direction == :-
      interval-interval%(30*60)
    else
      interval-interval%(30*60)+30*60
    end
  end

  def self.round_timestamp(timestamp,direction = :-)
    #find the time from the beginning of the day
    d = DateTime.strptime(timestamp.strftime("%Y-%m-%d 00:00:00 #{PresenceController.actual_timezone(timestamp)}"),"%Y-%m-%d %H:%M:%S %Z")

    #round it to the last half an hour
    if direction == :-
      d2 = (timestamp.to_i - d.to_i)%(60*30)
    else
      d2 = (timestamp.to_i - d.to_i)%(60*30)-30*60
    end

    #rebuild the timestamp
    # DateTime.strptime("#{timestamp.strftime("%Y-%m-%d")} #{"#{d2/3600}:#{((d2%3600)/60).to_s.rjust(2,'0')}:#{(((d2%3600)%60)).to_s.rjust(2,'0')}"}", "%Y-%m-%d %H:%M:%S")

    DateTime.strptime("#{timestamp.strftime("%Y-%m-%d")} #{(timestamp-d2).strftime("%H:%M:%S")} #{PresenceController.actual_timezone(timestamp)}", "%Y-%m-%d %H:%M:%S %Z")

  end

  def self.recalculate(date,person,dont_create = [])

    #remove previously recorded data
    PresenceRecord.where(date: date, person: person).each do |pr|
      pr.delete
    end

    #get delay leave
    delay_leave = LeaveCode.find_by(code: 'ORIT')
    no_delay_leave = LeaveCode.find_by(code: 'Ritardo avvisato')
    no_break_delay_leave = LeaveCode.find_by(code: 'Rit. pausa avvisato')
    GrantedLeave.where(person: person, leave_code: delay_leave, date: date).each do |gl|
      gl.delete
    end

    #get badges
    badges = person.badges(date)

    #count day's working time
    actual_total = 0

    #get day schedule
    working_schedule = WorkingSchedule.get_schedule(date,person)

    #for every timestamp on that day with those badges calculate records
    if badges.empty?
      presence_timestamps = []
    else
      presence_timestamps = PresenceTimestamp.where("deleted = 0 and sensor_id in (select id from sensors where presence_relevant = 1) "\
                          "and badge_id in (#{badges.map{|b|b.id}.join (',')})").where("(year(time) = #{date.strftime('%Y')} and month(time) = #{date.strftime('%-m')} "\
                          "and day(time) = #{date.strftime('%-d')})").order(time: :asc).to_a
    end
    previous_record = nil

    presence_timestamps.each_with_index do |pts,index|

      if index%2 == 0

        next_pts = presence_timestamps[index+1]
        last_record = presence_timestamps[index+2].nil?

        #if timestamp is even (starting from 0) it's an entering ts
        pts.update(entering: true)

        #calculate entering and exit
        if index == 0 && !working_schedule.nil?
          #if it's the first timestamp of the day compare starting time with agreed schedule
          # calculated_start = DateTime.strptime("#{date.strftime("%Y-%m-%d")} #{working_schedule.agreement_from.strftime("%H:%M:%S")}","%Y-%m-%d %H:%M:%S")

          # If there's a granted leave for the starting of the day set starting time accordingly
          starting_leaves = GrantedLeave.where(date: date, person: person).select{ |gl| gl.from <= working_schedule.agreement_from(date) && gl.leave_code != delay_leave}

          if starting_leaves.count > 0
            starting_time = starting_leaves.first.to
          else
            starting_time = working_schedule.transform_to_date(pts.time,:agreement_from)
          end

          if (pts.time).strftime('%H:%M') < starting_time.strftime('%H:%M')
            calculated_start = PresenceRecord.round_timestamp(pts.time,:+)
          else
            calculated_start = starting_time
          end

          #if there's a delay create a leave
          if pts.time.strftime('%H:%M') > (starting_time + working_schedule.flexibility.minutes).strftime('%H:%M')
            anomaly = 'Ritardo ingresso'
            #calculate delay fine
            unless GrantedLeave.where(date: date, person: person, leave_code: no_delay_leave).count > 0 or dont_create.include?(delay_leave)
              delay = PresenceRecord.round_delay(pts.time - starting_time)

              GrantedLeave.create(person: person,
                                  leave_code: delay_leave,
                                  date: date,
                                  from: starting_time,
                                  to: starting_time+delay.minutes
                                  )

            end
          end

          #check delay
          # if pts.time.strftime("%H:%M") > working_schedule.agreement_from.strftime("%H:%M")
          #   delay = Time.strptime("#{pts.time.strftime("%H:%M")}","%H:%M") - Time.strptime("#{working_schedule.agreement_from.strftime("%H:%M")}","%H:%M")
          #   delayed = 15/delay.to_i+1
          #   byebug
          # end
        else

          if previous_record.nil?
            calculated_start = pts.time.to_datetime
          elsif previous_record[:break]
            #if the previous record i a break start from when it ended
            calculated_start = previous_record.calculated_end
          else
            #otherwise get it from the timestamp
            calculated_start = pts.time.to_datetime
          end
        end
        if next_pts.nil?
          #if it's the last timestamp, ending time is open
          calculated_end = nil
        else
          #otherwise
          # if presence_timestamps[index+2].nil? && !working_schedule.nil?
          #   #if the next is the last get ending time from working schedule
          #   # calculated_end = DateTime.strptime("#{date.strftime("%Y-%m-%d")} #{working_schedule.agreement_to.strftime("%H:%M:%S")}","%Y-%m-%d %H:%M:%S")
          #   calculated_end = PresenceRecord.round_timestamp(next_pts.time)
          # else

            #if not get it from the next timestamp
            calculated_end = next_pts.nil? ? nil : next_pts.time.to_datetime
          # end
        end

        previous_record = PresenceRecord.create(date: date,
                            person: person,
                            start_ts: pts,
                            end_ts: next_pts,
                            calculated_start: calculated_start,
                            calculated_end: calculated_end,
                            actual_duration: next_pts.nil? ? 0 : (next_pts.time - pts.time).round,
                            calculated_duration: next_pts.nil? ? 0 : (calculated_end.to_i - calculated_start.to_i),
                            anomaly: anomaly,
                            break: false)

        unless previous_record.end_ts.nil?
          previous_record.check_timesheets(previous_record.end_ts.time)
        end
        actual_total += next_pts.nil? ? 0 : (next_pts.time - pts.time).round
      else

        next_pts = presence_timestamps[index+1]

        #if timestamp is odd (starting from 0) it's an exiting ts
        pts.update(entering: false)

        #calculate entering and exit (if it's the last one it was already registered as the ending of the previous)
        unless next_pts.nil?

          #start must be the pts' time
          calculated_start = pts.time.utc.to_datetime

          #end will be the rounded next timestamp
          # if working_schedule.nil?
          #   calculated_end = next_pts.time.to_datetime
          # else
          #   calculated_end = pts.time+working_schedule.break.minutes
          # end

          break_time = PresenceRecord.round_interval(next_pts.time - pts.time,:+)
          br = working_schedule.nil? ? break_time : working_schedule.break * 60
          ending_leaves = GrantedLeave.where(date: date, person: person).where("('#{(pts.time+br+PresenceController.actual_offset(pts.time).hours).strftime("%Y-%m-%d %H:%M:%S")}' between granted_leaves.from and granted_leaves.to) and granted_leaves.leave_code_id != #{delay_leave.id}")

          if ending_leaves.count > 0
            calculated_end = ending_leaves.first.to
          else
            calculated_end = pts.time.utc+(break_time > br ? br : break_time)
          end

          previous_record = PresenceRecord.new(date: date,
                              person: person,
                              start_ts: pts,
                              end_ts: next_pts,
                              calculated_start: calculated_start,
                              calculated_end: calculated_end,
                              actual_duration: next_pts.nil? ? 0 : (next_pts.time - pts.time).round,
                              calculated_duration: round_interval(calculated_end.to_i - calculated_start.to_i),
                              break: true)
          unless working_schedule.nil?
            if previous_record.actual_duration-1.minutes > working_schedule.break * 60
              previous_record.anomaly = 'Ritardo pausa'

              #if there's a delay create a leave

              unless GrantedLeave.where(date: date, person: person, leave_code: no_break_delay_leave).count > 0 or dont_create.include?(delay_leave)
                delay = PresenceRecord.round_delay(previous_record.actual_duration - working_schedule.break * 60)

                GrantedLeave.create(person: person,
                                    leave_code: delay_leave,
                                    date: date,
                                    from: next_pts.time,
                                    to: next_pts.time+delay.minutes
                                    )

              end
            end
          end
          previous_record.save

        end
      end
    end

    c_total = 0
    PresenceRecord.where(date: date, person: person, break: false).each do |pr|
      # c_total += pr.actual_duration
      c_total += pr.calculated_duration
    end

    # GrantedLeave.where(date: date, person: person).each do |gl|
    #   c_total += gl.duration(date) * gl.leave_code.afterhours
    # end
    PresenceRecord.where(date: date, person: person).each do |pr|
      pr.update(set_day_time: round_interval(c_total))
    end
  end

end
