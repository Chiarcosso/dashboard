class WorkshopOperation < ApplicationRecord

  belongs_to :worksheet
  belongs_to :user
  has_one :vehicle, through: :worksheet
  has_many :timesheet_records

  scope :to_notification, ->(protocol) { where(myofficina_reference: protocol.to_i) }

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{((self.real_duration.to_i/60)%60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
  end

  def operator
    self.user.person unless self.user.nil?
  end

  def self.reset_worksheet
    WorkshopOperation.all.each do |wo|
      wo.reset_worksheet
    end
  end

  def start(opts = {ts: nil, user: nil, note: nil})

    opts[:ts] = DateTime.now if opts[:ts].nil?
    opts[:user] = self.user if opts[:user].nil?
    worksheet = self.worksheet

    if self.user.nil?

      @workshop_operation = self

      # Unclaimed operation
      new_log = "Operazione nr. #{self.id} iniziata da #{opts[:user].person.complete_name}, il #{opts[:ts].strftime('%d/%m/%Y')} alle #{opts[:ts].strftime('%H:%M:%S')}."
      self.update(
        paused: false,
        user: opts[:user],
        starting_time: opts[:ts],
        last_starting_time: opts[:ts],
        log: "#{self.log}\n #{new_log}"
      )


    elsif self.user != opts[:user]

      # Operation of another user
      @workshop_operation = WorkshopOperation.create(
        name: self.name,
        paused: false,
        worksheet: self.worksheet,
        myofficina_reference: self.myofficina_reference,
        user: opts[:user],
        starting_time: opts[:ts],
        last_starting_time: opts[:ts]
      )
      new_log = "Operazione nr. #{@workshop_operation.id} iniziata da #{opts[:user].person.complete_name}, il #{opts[:ts].strftime('%d/%m/%Y')} alle #{opts[:ts].strftime('%H:%M:%S')}."
      @workshop_operation.update(log: new_log)

    else

      # Same user's operation
      @workshop_operation = self
      new_log = "Operazione nr. #{self.id} ripresa da #{opts[:user].person.complete_name}, il #{opts[:ts].strftime('%d/%m/%Y')} alle #{opts[:ts].strftime('%H:%M:%S')}."
      self.update(ending_time: nil, paused: false, last_starting_time: opts[:ts], log: "#{self.log}\n #{new_log}")

    end

    worksheet.update(last_starting_time: opts[:ts], last_stopping_time: nil, real_duration: worksheet.real_duration + opts[:ts].to_i - worksheet.last_starting_time.to_i, paused: false) unless worksheet.paused
    worksheet.update(log: "#{worksheet.log}\n #{new_log}")
    TimesheetRecord.close_all(opts[:user].person,Time.now)
    TimesheetRecord.create(person: opts[:user].person, workshop_operation: @workshop_operation, description: @workshop_operation.name, start: opts[:ts])
    WorkshopOperation.where(user: self.user,paused: false).reject{ |w| w == self }.each do |wo|
      wo.pause
    end
  end

  def pause(opts = {ts: nil, user: nil, note: nil})

    opts[:ts] = DateTime.now if opts[:ts].nil?
    opts[:user] = self.user if opts[:user].nil?
    worksheet = self.worksheet

    if self.paused
      duration = self.real_duration
    else
      duration = self.real_duration + opts[:ts].to_i - self.last_starting_time.to_i
    end
    new_log = "Operazione nr. #{self.id} interrotta da #{opts[:user].nil? ? 'N/D' : opts[:user].person.complete_name}, il #{opts[:ts].strftime('%d/%m/%Y')} alle #{opts[:ts].strftime('%H:%M:%S')}#{opts[:note].nil? ? '' : "(#{opts[:note]})"}."

    self.update(
      starting_time: self.starting_time.nil? ? self.created_at : self.starting_time,
      ending_time: nil,
      real_duration: duration,
      paused: true,
      last_starting_time: nil,
      last_stopping_time: opts[:ts],
      log: "#{self.log}\n #{new_log}"
    )

    # tr = TimesheetRecord.where(person: opts[:user].person, workshop_operation: self, stop: nil).order(:created_at => :asc).last
    # if tr.nil?
    #   tr = TimesheetRecord.create(person: opts[:user].person, workshop_operation: self, description: "#{self.name}", start: self.starting_time)
    # end
    # tr.update(start: self.starting_time) if tr.start.nil?
    self.timesheet_records.where(stop: nil).each do |tr|
      tr.close(Time.now)
    end

    worksheet.update(last_starting_time: opts[:ts], last_stopping_time: nil, real_duration: worksheet.real_duration + opts[:ts].to_i - worksheet.last_starting_time.to_i, paused: false) unless worksheet.paused
    worksheet.update(log: "#{worksheet.log}\n #{new_log}")

  end

  def close(opts = {ts: nil, user: nil, note: nil})
    opts[:ts] = DateTime.now if opts[:ts].nil?
    opts[:user] = self.user if opts[:user].nil?
    worksheet = self.worksheet

    if self.paused
      duration = self.real_duration
    else
      duration = self.real_duration + opts[:ts].to_i - self.last_starting_time.to_i
    end
    new_log = "Operazione nr. #{self.id} conclusa da #{opts[:user].nil? ? 'N/D' : opts[:user].person.complete_name}, il #{opts[:ts].strftime('%d/%m/%Y')} alle #{opts[:ts].strftime('%H:%M:%S')}#{opts[:note].nil? ? '' : "(#{opts[:note]})"}."
    self.update(
      starting_time: self.starting_time.nil? ? self.created_at : self.starting_time,
      ending_time: opts[:ts],
      real_duration: duration,
      paused: true,
      last_starting_time: nil,
      last_stopping_time: opts[:ts],
      log: "#{self.log}\n #{new_log}",
      notes: opts[:notes])

    # unless opts[:user].nil?
    #   tr = TimesheetRecord.where(person: opts[:user].person, workshop_operation: self, stop: nil).order(:created_at => :asc).last
    #   if tr.nil?
    #     tr = TimesheetRecord.create(person: opts[:user].person, workshop_operation: self, description: "#{self.name}", start: self.starting_time)
    #   end
    #   tr.update(start: self.starting_time) if tr.start.nil?
    #
    #   tr.update(stop: opts[:ts], minutes: ((opts[:ts].to_i - tr.start.to_i) / 60).ceil) unless tr.nil?
    # end
    self.timesheet_records.where(stop: nil).each do |tr|
      tr.close(Time.now)
    end
    worksheet.update(last_starting_time: opts[:ts], last_stopping_time: nil, real_duration: worksheet.real_duration + opts[:ts].to_i - worksheet.last_starting_time.to_i, paused: false) unless worksheet.paused
    worksheet.update(log: "#{worksheet.log}\n #{new_log}")
    #close notification there are no more operations
    if !self.myofficina_reference.nil? && WorkshopOperation.where(myofficina_reference: self.myofficina_reference).select{|wo| wo.ending_time.nil?}.size < 1

      sgn = self.ew_notification

      if sgn.nil? || sgn['SchedaInterventoProtocollo'].nil? || sgn['SchedaInterventoProtocollo'] == ''
        error = <<-ERR
          Error retriveing sgn:
          #{sgn.inspect}

          Operation:
          #{self.inspect}

          Worksheet:
          #{@worksheet.inspect}
        ERR

        ErrorMailer.error_report(error,"Chiusura operazione - SGN nr. #{self.myofficina_reference}").deliver_now
      end
      EurowinController::create_notification({
        'ProtocolloODL': sgn['SchedaInterventoProtocollo'].to_s,
        'AnnoODL': sgn['SchedaInterventoAnno'].to_s,
        'ProtocolloSGN': sgn['Protocollo'].to_s,
        'AnnoSGN': sgn['Anno'].to_s,
        'DataIntervento': sgn['DataSegnalazione'].to_s,
        'FlagRiparato': 'true',
        'CodiceOfficina': "0"
      })
    end

  end

  def reset_worksheet
    odl = EurowinController.get_odl_from_notification(self.myofficina_reference)
    if odl.nil? || (odl['CodiceAnagrafico'] != 'OFF00001' && odl['CodiceAnagrafico'] == 'OFF00047')
      self.delete
    else
      self.update(worksheet: Worksheet.find_or_create_by_code("EWC*#{odl['Protocollo']}"))
    end
  end

  def self.to_notification_or_create(sgn)

    WorkshopOperation.create(name: 'Lavorazione', myofficina_reference: sgn['Protocollo'], worksheet: Worksheet.find_by(code: "EWC*#{sgn['SchedaInterventoProtocollo']}")) if WorkshopOperation.to_notification(sgn['Protocollo']).count < 1
    WorkshopOperation.to_notification(sgn['Protocollo'])
  end

  def ew_notification
    EurowinController::get_notification(self.myofficina_reference) unless self.myofficina_reference.nil?
  end

  def self.get_from_sgn sgn
    WorkshopOperation.where(myofficina_reference: sgn)
  end

  def siblings
    WorkshopOperation.where(myofficina_reference: self.myofficina_reference) - [self]
  end

  def self.exist_or_create(worksheet,sgn)
    WorkshopOperation.create(name: 'Lavorazione', myofficina_reference: sgn, worksheet: worksheet) unless WorkshopOperation.where(myofficina_reference: sgn).count > 0
  end
end
