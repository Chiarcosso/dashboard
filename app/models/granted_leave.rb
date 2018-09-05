class GrantedLeave < ApplicationRecord

  belongs_to :leave_code
  belongs_to :person

  def time_in_leave(time = Time.now)

    if time >= self.from && time <= self.to
      true
    else
      false
    end
  end

  def duration(comparison_date)

    #if the comparison date is festive return 0
    return 0 if Festivity.is_festive?(comparison_date)

    #if the comparison date is between the leave dates
    if comparison_date.strftime("%Y-%m-%d") >= self.from.strftime("%Y-%m-%d") && comparison_date.strftime("%Y-%m-%d") <= self.to.strftime("%Y-%m-%d")

      #if is less than a day
      if self.from.strftime("%Y-%m-%d") == self.to.strftime("%Y-%m-%d")
        return (self.to - self.from).to_i - self.break.minutes
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

  def self.check_journal

    date = Time.now.strftime('%Y-%m-%d')

    #get journal leaves
    journal = MssqlReference.query({table: 'GIORNALE', where: {IDViaggi: ['MAMAMA','FEFEFE','PEPEPE','INININ'], Data: date}})

    #get dashboard leaves
    dashboard = GrantedLeave.where("'#{Time.now.strftime('%Y-%m-%d')}' between date_format(granted_leaves.from,'%Y-%m-%d') and date_format(granted_leaves.to,'%Y-%m-%d') "\
                      "and granted_leaves.leave_code_id != #{LeaveCode.find_by(code: 'ORIT').id} "\
                      "and granted_leaves.leave_code_id != #{LeaveCode.find_by(code: 'Ritardo avvisato').id}")

    #get leave codes
    leave_codes = {
      'FEFEFE': LeaveCode.find_by(code: 'FERI'),
      'MAMAMA': LeaveCode.find_by(code: 'MALA'),
      'INININ': LeaveCode.find_by(code: 'INFO'),
      'PEPEPE': [LeaveCode.find_by(code: 'PHAN'),LeaveCode.find_by(code: 'PERM'),LeaveCode.find_by(code: 'PRN')]
    }

    text = ''

    #check whether all jornal leaves are matched
    journal.each do |j|
      person = Person.find_or_create({mssql_id: j['IDAutista'], table: 'Autisti'})


      if j['IDViaggi'] == 'PEPEPE'
        if dashboard.select{ |d| d.person == person && leave_codes[:PEPEPE].include?(d.leave_code) && d.to.strftime('%Y-%m-%d') == j['DataAl'].strftime('%Y-%m-%d')}.size == 0
          text += "Il #{j['Data'].strftime('%d/%m/%Y')} e' presente sul giornale un permesso #{j['IDViaggi']} di #{person.list_name}, fino al #{j['DataAl'].nil? ? '' : j['DataAl'].strftime("%d/%m/%Y")} che manca in dashboard (IDPosizione: #{j['IDPosizione']}).\n"
        end
      else
        if dashboard.select{ |d| d.person == person && d.leave_code == leave_codes[j['IDViaggi'].to_sym] && d.to.strftime('%Y-%m-%d') == j['DataAl'].strftime('%Y-%m-%d')}.size == 0
          text += "Il #{j['Data'].strftime('%d/%m/%Y')} e' presente sul giornale un permesso #{j['IDViaggi']} di #{person.list_name}, fino al #{j['DataAl'].nil? ? '' : j['DataAl'].strftime("%d/%m/%Y")} che manca in dashboard. (IDPosizione: #{j['IDPosizione']})\n"
        end
      end
    end

    text += "\n\n"
    #check whether all dashboard leaves are matched
    dashboard.each do |d|
      next if MssqlReference.query({table: 'Autisti', where: {IdAutista: d.person.mssql_references.map{ |r| r.remote_object_id }, IdMansione: [1,5]}}).count == 0
      if leave_codes[:PEPEPE].include?(d.leave_code)
        trip_id = 'PEPEPE'
      else
        trip_id = leave_codes.key(d.leave_code).to_s
      end

      if MssqlReference.query({
        table: 'GIORNALE',
        where: {
          'IDAutista': d.person.mssql_references.map{|p| p.remote_object_id},
          'data': date,
          'DataAl': d.to.strftime('%Y-%m-%d'),
          'IDViaggi': trip_id
        }
        }).count == 0
        text += "Il #{date.split('-').reverse.join('/')} nel giornale manca la riga per il permesso di #{d.person.list_name} per #{d.leave_code.code}, dal #{d.from.strftime("%d/%m/%Y")} al #{d.to.strftime("%d/%m/%Y")}\n"
      end
    end
    text = 'Non ci sono discordanze fra il giornale e dashboard.' if text == "\n\n"
    HumanResourcesMailer.journal_check(text).deliver_now
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
