class PresenceController < ApplicationController

  before_action :get_person
  before_action :get_month_year
  before_action :get_tab
  before_action :get_working_schedule, only: [:edit_working_schedule, :delete_working_schedule]
  before_action :get_festivity, only: [:edit_festivity, :delete_festivity]
  before_action :get_leave_code, only: [:edit_leave_code, :delete_leave_code]

  def manage_festivities
    begin
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
        format.html { render 'festivities/index' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def manage_presence
    begin
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def self.read_timestamps(opts = {:get_current => true})

    #set starting date
    if opts[:get_all]
      #if get_all start from january 2015
      year = 2015
      month = 1
    elsif opts[:get_current]
      #if get_current (default) start from now and get last_timestamp
      last_timestamp = PresenceTimestamp.real_timestamps.order(time: :desc).first
      year = Date.today.strftime("%Y").to_i
      month = Date.today.strftime('%m').to_i
      # if last_timestamp.nil?
      #   year = Date.today.strftime("%Y").to_i
      #   month = Date.today.strftime('%m').to_i
      # else
      #   year = last_timestamp.time.strftime("%Y").to_i
      #   month = last_timestamp.time.strftime("%m").to_i
      # end
    elsif !opts[:month].nil? && !opts[:year].nil?
      #if incorret opts rebuild them
      if opts[:year] < 2015
        year = 2015
      else
        year = opts[:year]
      end
      if opts[:month] != 12
        month = opts[:month]%12
      else
        month = 12
      end
    else
      #default start from last timestamp
      last_timestamp = PresenceTimestamp.real_timestamps.order(time: :desc).first
      if last_timestamp.nil?
        year = 2015
        month = 1
      else
        year = last_timestamp.time.strftime("%Y").to_i
        month = last_timestamp.time.strftime("%m").to_i
      end
    end

    #first filename
    fname = "#{ENV['RAILS_CAME_PATH']}Sto#{month.to_s.rjust(2,'0')}#{year}.sto"
    @special_logger.info("Start importing #{fname}")

    #while the next file exists read it and store information
    if File.exist?(fname)

      fh = File.open(fname)
      rf = fh.read.force_encoding('iso-8859-1')
      row = 1
      last_date = nil
      people = Hash.new

      #scan the line
      rf.scan(/\d+\x01+\d+\x01+.*\( *([A-Za-z]?\d*) *\).*\x01+(\d*)\x01+([\d \:\/]*)\x01+/) do |badge,sensor,timestamp|

        #if we are over the last recorded timestamp start recording
        if last_timestamp.nil? || (opts[:get_current] && last_timestamp.time < DateTime.strptime(timestamp,"%d/%m/%y %H:%M:%S"))

          #get badge and sensor
          badge = Badge.find_or_create(badge.gsub(/\s+/,''))
          sensor = Sensor.find_by(number: sensor.to_i)

          #record timestamp
          time = DateTime.strptime(timestamp+' UTC',"%d/%m/%y %H:%M:%S %Z")-2.hours
          ts = PresenceTimestamp.find_or_create(badge: badge, sensor: sensor, time: time,row: row, file: fname)

          #set last_date and person
          last_date = time if last_date.nil?
          person = badge.person(last_date)

          #add person if exists and the sensor is relevant
          people[person.id.to_s] = person unless person.nil? || !sensor.presence_relevant

          #if the day changed
          if time.strftime("%Y-%m-%d") != last_date.strftime("%Y-%m-%d")
            # calculate PresenceRecords for all people
            people.each do |k,p|
              PresenceRecord.recalculate(last_date,p)
            end
            #and reset people
            people = Hash.new
          end
          last_date = time

        end
        row += 1
      end

      # #increment month and year
      # month += 1
      # if month > 12
      #   month = 1
      #   year += 1
      # end
      fh.close
      # sleep 1
      # #next filename
      # fname = "#{ENV['RAILS_CAME_PATH']}Sto#{month.to_s.rjust(2,'0')}#{year}.sto"
    end
  end

  def add_timestamp
    begin
      begin
        timestamp = DateTime.strptime("#{params.require(:date)} #{params.require(:time)}:00 CEST", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Ora non valida.'
      end
      begin
        sensor = Sensor.find(params.require(:sensor).to_i)
        raise 'Selezionare il sensore' if sensor.nil?
      rescue
        @error = 'Selezionare il sensore' if sensor.nil?
      end
      person = Person.find(params.require(:person).to_i)
      badge = person.badges(Date.strptime("#{params.require(:date)}", "%Y-%m-%d")).first
      if PresenceTimestamp.find_by(time: timestamp, badge: badge, sensor: sensor).nil?
        PresenceTimestamp.create(time: timestamp, badge: badge, added: true, file: nil, row: nil, sensor: sensor)
      else
        PresenceTimestamp.find_by(time: timestamp, badge: badge, sensor: sensor).update(deleted: false)
      end

      PresenceRecord.recalculate(timestamp,person)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n") if @error.nil?
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def delete_timestamp
    begin
      pr = PresenceTimestamp.find(params.require(:id))
      date = pr.time
      person = pr.badge.person(date)
      pr.update(deleted: true)
      PresenceRecord.recalculate(date,person)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n")
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def actual_timezone(date = Time.zone.today)
    date.dst? ? 'CEST' : 'CET'
  end

  def actual_offset(date = Time.zone.today)
    date.dst? ? -2 : -1
  end

  def self.actual_timezone(date = Time.zone.today)
    date.dst? ? 'CEST' : 'CET'
  end

  def self.actual_offset(date = Time.zone.today)
    date.dst? ? -2 : -1
  end

  def add_long_leave
    begin
      begin
        #get the working schedule for that day and set from timestamp
        date_from =Time.strptime(params.require(:date_from),"%Y-%m-%d")
        ws = WorkingSchedule.get_schedule(date_from,@person)
        from = DateTime.strptime("#{params.require(:date_from)} #{ws.contract_from.strftime("%H:%M:%S")} #{self.actual_timezone(date_from)}", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Data inizio non valida.'
      end
      begin
        #get the working schedule for that day and set from timestamp
        date_to = Time.strptime(params.require(:date_to),"%Y-%m-%d")
        ws = WorkingSchedule.get_schedule(date_to,@person)
        to = DateTime.strptime("#{params.require(:date_to)} #{ws.contract_to.strftime("%H:%M:%S")} #{self.actual_timezone(date_to)}", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Data fine non valida.'
      end
      person = Person.find(params.require(:person).to_i)
      leave_code = LeaveCode.find(params.require(:leave_code).to_i)
      # date = Date.strptime(params.require(:date),"%Y-%m-%d")

      if GrantedLeave.find_by(from: from, to: to, person: person, leave_code: leave_code).nil?
        GrantedLeave.create(from: from, to: to, person: person, leave_code: leave_code)
      end

      # PresenceRecord.recalculate(date,@person)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n") if @error.nil?
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def add_leave
    begin
      begin
        from = DateTime.strptime("#{params.require(:date)} #{params.require(:time_from)}:00 CEST", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Ora inizio valida.'
      end
      begin
        to = DateTime.strptime("#{params.require(:date)} #{params.require(:time_to)}:00 CEST", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Ora fine non valida.'
      end
      person = Person.find(params.require(:person).to_i)
      leave_code = LeaveCode.find(params.require(:leave_code).to_i)
      date = Date.strptime(params.require(:date),"%Y-%m-%d")

      if GrantedLeave.find_by(from: from, to: to, person: person, leave_code: leave_code).nil?
        GrantedLeave.create(from: from, to: to, person: person, leave_code: leave_code)
      end

      # PresenceRecord.recalculate(date,@person)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n") if @error.nil?
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def delete_leave
    begin
      gl = GrantedLeave.find(params.require(:id))
      date  = Date.strptime(params.require(:date),"%Y-%m-%d")
      gl.delete
      # PresenceRecord.recalculate(date,@person)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n")
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def add_festivity
    begin
      Festivity.create(festivity_params)
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def edit_festivity
    begin
      @festivity.update(festivity_params)
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def delete_festivity
    begin
      @festivity.destroy
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def add_leave_code
    begin
      LeaveCode.create(leave_code_params)
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def edit_leave_code
    begin
      @leave_code.update(leave_code_params)
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def delete_leave_code
    begin
      @leave_code.destroy
      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def add_working_schedule
    begin
      WorkingSchedule.create(working_schedule_params)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def edit_working_schedule
    begin
      @working_schedule.update(working_schedule_params)
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def delete_working_schedule
    begin
      @working_schedule.destroy
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  private

  def get_person
    if params['person-select'].nil?
      if params['person'].nil? || params['person'] == ''
        @person = Person.order(:surname).first
      else
        @person = Person.find(params.require(:person).to_i)
      end
    else
      @person = Person.find(params.require('person-select').to_i)
    end
  end

  def get_month_year
    if params[:month].nil?
      @month = (Date.today-20.days).strftime("%m").to_i
    else
      @month = params.require('month').to_i+1
    end
    if params[:year].nil?
      @year = (Date.today-20.days).strftime("%Y").to_i
    else
      @year = params.require('year').to_i
    end
  end

  def get_working_schedule
    @working_schedule = WorkingSchedule.find(params.require(:id).to_i)
    @person = @working_schedule.person
  end

  def get_festivity
    @festivity = Festivity.find(params.require(:id).to_i)
  end

  def get_leave_code
    @leave_code = LeaveCode.find(params.require(:id).to_i)
  end

  def festivity_params
    params.require(:festivity).permit(:name, :day, :month, :year)
  end

  def leave_code_params
    params.require(:leave_code).permit(:code, :afterhours, :description)
  end

  def working_schedule_params
    p = Hash.new
    params.require(:working_schedule).permit(:weekday, :agreement_from, :agreement_to, :contract_from, :contract_to, :break, :months_unpaid_days)
    p[:person] = @person
    p[:weekday] = params[:working_schedule][:weekday]
    p[:agreement_from] = params[:working_schedule][:agreement_from] == ''? nil :Time.strptime(params[:working_schedule][:agreement_from],"%H:%M")
    p[:agreement_to] = params[:working_schedule][:agreement_to] == ''? nil :Time.strptime(params[:working_schedule][:agreement_to],"%H:%M")
    p[:contract_from] = params[:working_schedule][:contract_from] == ''? nil : Time.strptime(params[:working_schedule][:contract_from],"%H:%M")
    p[:contract_to] = params[:working_schedule][:contract_to] == ''? nil :Time.strptime(params[:working_schedule][:contract_to],"%H:%M")
    p[:break] = params[:working_schedule][:break]
    p[:months_unpaid_days] = params[:working_schedule][:months_unpaid_days]
    if p[:agreement_from].nil? ^ p[:agreement_to].nil?
      raise "L'orario concordato non e' completo."
    end
    if p[:contract_from].nil? ^ p[:contract_to].nil?
      raise "L'orario da contratto non e' completo."
    end
    if p[:contract_from].nil? && p[:contract_to].nil? && p[:agreement_from].nil? && p[:agreement_to].nil?
      raise "Non sono stati impostati gli orari."
    end
    p
  end

  def get_tab
    @tab = params['tab']
  end

  def self.special_logger
    @@mssql_reference_logger ||= Logger.new("#{Rails.root}/log/presence.log")
  end
end
