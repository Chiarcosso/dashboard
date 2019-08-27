class PresenceController < ApplicationController

  before_action :get_person
  before_action :get_month_year
  before_action :get_tab
  before_action :get_scroll
  before_action :get_from_to, only: [:vacation_calendar]
  before_action :get_working_schedule, only: [:edit_working_schedule, :delete_working_schedule]
  before_action :get_festivity, only: [:edit_festivity, :delete_festivity]
  before_action :get_leave_code, only: [:edit_leave_code, :delete_leave_code]
  # after_action :change_tab, only: [
  #   :recalculate_day,
  #   :manage_presence,
  #   :change_presence_time,
  #   :add_timestamp,
  #   :delete_timestamp,
  #   :add_long_leave,
  #   :add_leave,
  #   :delete_leave,
  #   :add_working_schedule,
  #   :edit_working_schedule,
  #   :delete_working_schedule
  # ]

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

  def vacation_calendar
    begin
      @zoom = params[:zoom].nil? ? 1 : params[:zoom].to_i
      driver_role = CompanyRelation.find_by(name: 'Autista')
      mechanic_role = CompanyRelation.find_by(name: 'Meccanico')
      roaming_mechanic_role = CompanyRelation.find_by(name: 'Meccanico trasfertista')
      chief_mechanic_role = CompanyRelation.find_by(name: 'Capo Officina')

      leaves = GrantedLeave.absence.in_range(@from,@to)
      people = Person.active_people(@from).order(surname: :asc)
      @people_leaves = Hash.new
      @people_leaves['Autisti'] = Hash.new
      @people_leaves['Meccanici'] = Hash.new
      @people_leaves['Impiegati'] = Hash.new
      people.each do |p|
        if p.company_relations.include?(driver_role)
          @people_leaves['Autisti'][p.list_name] = leaves.select{ |gl| gl.person == p}
        elsif p.company_relations.include?(mechanic_role) || p.roles.include?(roaming_mechanic_role) || p.roles.include?(chief_mechanic_role)
          @people_leaves['Meccanici'][p.list_name] = leaves.select{ |gl| gl.person == p}
        else
          @people_leaves['Impiegati'][p.list_name] = leaves.select{ |gl| gl.person == p}
        end
      end
      respond_to do |format|
        format.js { render partial: 'presence/vacation_calendar_js' }
        format.html { render 'presence/vacation_calendar' }
      end
    rescue Exception => e

      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def info_timestamps
    begin
      @day = Date.strptime(params.require(:date),"%Y-%m-%d")
      @person = Person.find(params.require(:person).to_i)
      respond_to do |format|
        format.js { render partial: 'presence/infobox_timestamps' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def recalculate_day

    PresenceRecord.recalculate(@day,@person)

    begin
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        @pp_tab_row = "pp#{@day.strftime('%-d')}"
        @pd_tab_row = "pd#{@person.id}"
        @bp_tab_row = "bp#{@person.id}"
        format.js { render partial: 'presence/presence_rows_js' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join('<br>')
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def manage_presence
    begin
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      change_tab
    rescue Exception => e
      @error = e.message+e.backtrace.join('<br>')

      # byebug
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
    fname = "#{ENV['RAILS_CAME_LOCAL_PATH']}/Sto#{month.to_s.rjust(2,'0')}#{year}.sto"
    special_logger.info("Start importing #{fname}\n")

    begin
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
            time = DateTime.strptime(timestamp+' UTC',"%d/%m/%y %H:%M:%S %Z")+actual_offset(Date.strptime(timestamp,"%d/%m/%y %H:%M:%S")).hours
            ts = PresenceTimestamp.find_or_create(badge: badge, sensor: sensor, time: time,row: row, file: fname)
            special_logger.info(ts.inspect)

            #set last_date and person
            last_date = time if last_date.nil?
            person = badge.day_holder(last_date)

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

        #last recalculation round
        people.each do |k,p|
          PresenceRecord.recalculate(last_date,p)
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
    rescue Exception => e
      special_logger.error("#{e.message}\n\n#{e.backtrace.join("\n")}\n")
    end
  end

  def change_tab

    respond_to do |format|
      case @tab
      when 'presence' then
        @tabsub = ['#presence','presence/presence']
        @tabsub2 = ['#presence_day','presence/presence_day']
        @tabsub3 = ['#schedules','presence/schedules']
      when 'presence_day' then
        @tabsub = ['#presence_day','presence/presence_day']
        @tabsub2 = ['#presence','presence/presence']
      when 'building_presence' then
        @tabsub = ['#building_presence','presence/building_presence']
      when 'schedules' then
        @tabsub = ['#schedules','presence/schedules']
        @tabsub2 = ['#presence','presence/presence']
      end
      format.js { render partial: 'presence/manage_js' }
      format.html { render 'presence/index' }
    end
  end

  def loadrow
    @day = Time.strptime(params.require(:day),"%Y-%m-%d")
    @person = Person.find(params.require(:person))
    respond_to do |format|
      case params.require(:area)
      when 'bp' then
        format.js { render partial: 'presence/building_records', locals: {p: @person}}
      when 'pd' then
        format.js { render partial: 'presence/people_records', locals: {person: @person, day: @day}}
      when 'pp' then
        format.js { render partial: 'presence/days_records', locals: {person: @person, day: @day}}
      end
    end
  end

  def change_presence_time
    begin

      time = Time.strptime("#{params.require(:date)} #{params.require(:set_total)}","%Y-%m-%d %H:%M") - Time.strptime("#{params.require(:date)} 00:00","%Y-%m-%d %H:%M")
      PresenceRecord.where(date: Date.strptime(params.require(:date),"%Y-%m-%d"),person: @person).each { |pr| pr.update(set_day_time: time)}
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        @pp_tab_row = "pp#{@day.strftime('%-d')}"
        @pd_tab_row = "pd#{@person.id}"
        @bp_tab_row = "bp#{@person.id}"
        format.js { render partial: 'presence/presence_rows_js' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n") if @error.nil?
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def add_timestamp
    begin
      begin
        timestamp = DateTime.strptime("#{params.require(:date)} #{params.require(:time)}:00 #{self.actual_timezone(Date.strptime(params.require(:date),"%Y-%m-%d"))}", "%Y-%m-%d %H:%M:%S %Z")
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
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        @pp_tab_row = "pp#{@day.strftime('%-d')}"
        @pd_tab_row = "pd#{@person.id}"
        @bp_tab_row = "bp#{@person.id}"
        format.js { render partial: 'presence/presence_rows_js' }
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
      person = pr.badge.day_holder(date)
      pr.update(deleted: true)
      PresenceRecord.recalculate(date,person)
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        @pp_tab_row = "pp#{@day.strftime('%-d')}"
        @pd_tab_row = "pd#{@person.id}"
        @bp_tab_row = "bp#{@person.id}"
        format.js { render partial: 'presence/presence_rows_js' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n")
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def actual_timezone(date = Time.zone.today)
    Time.parse(date.to_s).dst? ? 'CEST' : 'CET'
  end

  def actual_offset(date = Time.zone.today)
    Time.parse(date.to_s).dst? ? -2 : -1
  end

  def self.actual_timezone(date = Time.zone.today)
    Time.parse(date.to_s).dst? ? 'CEST' : 'CET'
  end

  def self.actual_offset(date = Time.zone.today)
    Time.parse(date.to_s).dst? ? -2 : -1
  end

  # def recalculate_day
  #   PresenceRecord.recalculate(@day,@person)
  # end

  def add_long_leave
    begin
      begin
        #get the working schedule for that day and set from timestamp
        date_from =Time.strptime(params.require(:date_from),"%Y-%m-%d")
        ws = WorkingSchedule.get_schedule(date_from,@person)
        if ws.nil? && !params[:time_from].nil?
          ws = WorkingSchedule.new(person: @person, contract_from_s:params[:time_from])
        end
        raise 'Orario data inizio non presente' if ws.nil?
        from = DateTime.strptime("#{params.require(:date_from)} #{ws.contract_from(Time.strptime(params.require(:date_from),"%Y-%m-%d")).utc.strftime("%H:%M:%S")}", "%Y-%m-%d %H:%M:%S")
        from = from-1.days if ws.contract_from_s == "00:00"
      rescue
        @error = 'Data/ora inizio non valida.'
      end
      begin
        #get the working schedule for that day and set from timestamp
        date_to = Time.strptime(params.require(:date_to),"%Y-%m-%d")
        ws = WorkingSchedule.get_schedule(date_to,@person)
        if ws.nil? && !params[:time_to].nil?
          ws = WorkingSchedule.new(person: @person, contract_to_s:params[:time_to])
        end
        raise 'Orario data fine non presente' if ws.nil?
        to = DateTime.strptime("#{params.require(:date_to)} #{ws.contract_to(Time.strptime(params.require(:date_to),"%Y-%m-%d")).utc.strftime("%H:%M:%S")}", "%Y-%m-%d %H:%M:%S")
        to = to-1.days if ws.contract_to_s == "00:00"
      rescue
        @error = 'Data/ora fine non valida.'
      end
      person = Person.find(params.require(:person).to_i)
      leave_code = LeaveCode.find(params.require(:leave_code).to_i)
      # date = Date.strptime(params.require(:date),"%Y-%m-%d")


      if GrantedLeave.find_by(from: from, to: to, person: person, leave_code: leave_code).nil?
        GrantedLeave.create(from: from, to: to, person: person, leave_code: leave_code, date: from.strftime("%Y-%m-%d") == to.strftime("%Y-%m-%d") ? from : nil)
      end

      date = from
      while date <= to do
        PresenceRecord.recalculate(date,@person)
        date += 1.days
      end
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        format.js { render partial: 'presence/presence_multiple_rows_js' }
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
        from = DateTime.strptime("#{params.require(:date)} #{params.require(:time_from)}:00 #{PresenceController.actual_timezone(params.require(:date))}", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Ora inizio valida.'
      end
      begin
        to = DateTime.strptime("#{params.require(:date)} #{params.require(:time_to)}:00  #{PresenceController.actual_timezone(params.require(:date))}", "%Y-%m-%d %H:%M:%S %Z")
      rescue
        @error = 'Ora fine non valida.'
      end
      person = Person.find(params.require(:person).to_i)
      leave_code = LeaveCode.find(params.require(:leave_code).to_i)
      date = Date.strptime(params.require(:date),"%Y-%m-%d")

      if GrantedLeave.find_by(from: from, to: to, person: person, leave_code: leave_code).nil?
        gl = GrantedLeave.create(from: from, to: to, person: person, leave_code: leave_code, date: date, break: params.require(:break).to_i)
      end

      PresenceRecord.recalculate(date,@person)
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab

      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        @pp_tab_row = "pp#{@day.strftime('%-d')}"
        @pd_tab_row = "pd#{@person.id}"
        @bp_tab_row = "bp#{@person.id}"
        format.js { render partial: 'presence/presence_rows_js' }
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
      from = gl.from
      to = gl.to
      deleted_code = gl.leave_code
      gl.delete
      date = from
      while date <= to do
        PresenceRecord.recalculate(date,@person,[deleted_code])
        date += 1.days
      end
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      #   format.html { render 'presence/index' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        if gl.long_leave?
          format.js { render partial: 'presence/presence_multiple_rows_js' }
        else
          @pp_tab_row = "pp#{@day.strftime('%-d')}"
          @pd_tab_row = "pd#{@person.id}"
          @bp_tab_row = "bp#{@person.id}"
          format.js { render partial: 'presence/presence_rows_js' }
        end
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
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        format.js { render partial: 'presence/presence_multiple_rows_js' }
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
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        format.js { render partial: 'presence/presence_multiple_rows_js' }
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
      # respond_to do |format|
      #   case @tab
      #   when 'presence' then
      #     @tabsub = ['#presence','presence/presence']
      #     @tabsub2 = ['#presence_day','presence/presence_day']
      #     @tabsub3 = ['#schedules','presence/schedules']
      #   when 'presence_day' then
      #     @tabsub = ['#presence_day','presence/presence_day']
      #     @tabsub2 = ['#presence','presence/presence']
      #   when 'building_presence' then
      #     @tabsub = ['#building_presence','presence/building_presence']
      #   when 'schedules' then
      #     @tabsub = ['#schedules','presence/schedules']
      #     @tabsub2 = ['#presence','presence/presence']
      #   end
      #   format.js { render partial: 'presence/manage_js' }
      # end
      # change_tab
      respond_to do |format|
        # case @tab
        # when 'presence' then
        #   @tab_row = "pp#{@day.strftime('%-d')}"
        #   format.js { render partial: 'presence/days_records_js' }
        # when 'presence_day' then
        #   @tab_row = "pd#{@person.id}"
        #   format.js { render partial: 'presence/people_records_js' }
        # end
        format.js { render partial: 'presence/presence_multiple_rows_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def add_badge_assignment
    begin
      badge = Badge.find(params.require(:badge_assignment).permit(:badge)[:badge].to_i)
      person = Person.find(params.require(:badge_assignment).permit(:person)[:person].to_i)

      from = Time.strptime(params.require(:badge_assignment).permit(:from)[:from],"%Y-%m-%d")
      to = Time.strptime(params.require(:badge_assignment).permit(:to)[:to],"%Y-%m-%d") unless params.require(:badge_assignment).permit(:to)[:to].nil? || params.require(:badge_assignment).permit(:to)[:to] == ''

      if badge.assigned?({from: from, to: to})
        raise "Il badge è assegnato a #{badge.holders({from: from, to: to}).map{ |p| p.list_name}.join(', ')} nel periodo specificato."
      else
        BadgeAssignment.create(badge: badge, person: person, from: from, to: to)
      end

      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      # @error += "\n\n#{e.backtrace.join("\n")}"
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def edit_badge_assignment
    begin
      badge_assignment = BadgeAssignment.find(params.require(:id))
      badge = badge_assignment.badge
      from = Time.strptime(params.require(:badge_assignment).permit(:from)[:from],"%Y-%m-%d")
      to = Time.strptime(params.require(:badge_assignment).permit(:to)[:to],"%Y-%m-%d") unless params.require(:badge_assignment).permit(:to)[:to].nil? || params.require(:badge_assignment).permit(:to)[:to] == ''
      holders = badge.holders({from: from, to: to, exclude: badge_assignment})
      if holders.count > 0
        raise "Il badge è assegnato a #{holders.map{ |p| p.list_name}.join(', ')} nel periodo specificato."
      else
        badge_assignment.update(from: from, to: to)
      end

      respond_to do |format|
        format.js { render partial: 'festivities/manage_js' }
      end
    rescue Exception => e
      @error = e.message
      # @error += "\n\n#{e.backtrace.join("\n")}"
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def download_csv
    csv = ''
    studio_codes = LeaveCode.where(studio_relevant: true)
    for day in 1..Time.days_in_month(@month-1,@year)
      date = Time.strptime("#{@year}-#{(@month-1).to_s.rjust(2,'0')}-#{day.to_s.rjust(2,'0')} 00:00:00","%Y-%m-%d %H:%M:%S")
      csv += "#{@person.list_name};#{date.strftime("%d/%m/%Y")};"
      GrantedLeave.where(person: @person).where("'#{date.strftime("%Y-%m-%d")}' = granted_leaves.date or ('#{date.strftime("%Y-%m-%d")}' between date(granted_leaves.from) and date(granted_leaves.to))").where("leave_code_id in (#{studio_codes.map{|sc| sc.id}.join(',')})").each do |gl|
        csv += "#{gl.duration_label(date,false)};#{gl.leave_code.code};" if gl.duration(date) > 0
      end
      csv += "\n"
    end
    respond_to do |format|
      format.csv  do
        send_data csv, filename:
        "#{@person.list_name}_#{date.strftime("%Y_%m")}.csv",
        type: "text/csv"
      end
    end
  end

  def print_absences
    motivation = params[:motivation] == 'true'

    pdf = Prawn::Document.new
    date = DateTime.strptime(params.require(:date),"%Y-%m-%d")
    pdf.text "Assenze del #{date.strftime("%d/%m/%Y")}",size: 26, font_style: :bold, align: :center
    pdf.move_down 40
    codes = LeaveCode.where(afterhours: true)


    # where = <<-QRY
    #
    # ('#{date.strftime("%Y-%m-%d")}' = date(granted_leaves.date)
    # or '#{date.strftime("%Y-%m-%d")}' between date(granted_leaves.from) and date(granted_leaves.to)
    # or (
    #   '#{(date+1.days).strftime("%Y-%m-%d")}' between date(granted_leaves.from) and date(granted_leaves.to)
    #   and datediff(granted_leaves.to,granted_leaves.from) > 1
    #   and ( date(granted_leaves.from) <> '#{(date+1.days).strftime("%Y-%m-%d")}'
    #     or (
    #     select id from granted_leaves pr
    #     where granted_leaves.person_id = pr.person_id
    #     and '#{date.strftime("%Y-%m-%d")}' = date(pr.date)
    #     and pr.leave_code_id in (#{codes.map{|lc| lc.id}.join(',')})
    #     ) is not null)
    # )) and leave_code_id in (#{codes.map{|lc| lc.id}.join(',')})
    #
    # QRY
    # tz = self.actual_offset(date) == -1 ? "-01:00" : "+02:00"
    # ntz = self.actual_offset(date+1.days) == -1 ? "-01:00" : "+02:00"

    where = <<-QRY

    ('#{date.in_time_zone('Europe/Rome').strftime("%Y-%m-%d")}' = date(granted_leaves.date)
    or '#{date.in_time_zone('Europe/Rome').strftime("%Y-%m-%d")}' between date(convert_tz(granted_leaves.from,'+00:00','+02:00')) and date(convert_tz(granted_leaves.to,'+00:00','+02:00'))
    or (
      ('#{(date.in_time_zone('Europe/Rome')+1.days).utc.strftime("%Y-%m-%d")}' = date(convert_tz(granted_leaves.date,'+00:00','+02:00'))
        or '#{(date+1.days).in_time_zone('Europe/Rome').strftime("%Y-%m-%d")}' between date(convert_tz(granted_leaves.from,'+00:00','+02:00')) and date(convert_tz(granted_leaves.to,'+00:00','+02:00')))
      and (
        select count(id) from granted_leaves subq where ('#{date.in_time_zone('Europe/Rome').strftime("%Y-%m-%d")}' = date(convert_tz(subq.from,'+00:00','+02:00'))
        or '#{date.in_time_zone('Europe/Rome').strftime("%Y-%m-%d")}' between date(convert_tz(subq.from,'+00:00','+02:00')) and date(convert_tz(subq.to,'+00:00','+02:00')))
        and granted_leaves.person_id = subq.person_id

      ) > 0
    )) and leave_code_id in (#{codes.map{|lc| lc.id}.join(',')})

    QRY

    leaves = GrantedLeave.where(where)

    driver_role = CompanyRelation.find_by(name: 'Autista')
    mechanic_role = CompanyRelation.find_by(name: 'Meccanico')
    roaming_mechanic_role = CompanyRelation.find_by(name: 'Meccanico trasfertista')
    chief_mechanic_role = CompanyRelation.find_by(name: 'Capo officina')

    drivers = leaves.select{ |gl| gl.person.company_relations.include?(driver_role)}
    mechanics = leaves.select{ |gl| gl.person.company_relations.include?(mechanic_role) || gl.person.company_relations.include?(roaming_mechanic_role) || gl.person.company_relations.include?(chief_mechanic_role)}
    office_workers = leaves.reject{ |gl| gl.person.company_relations.include?(mechanic_role) || gl.person.company_relations.include?(roaming_mechanic_role) || gl.person.company_relations.include?(chief_mechanic_role) || gl.person.company_relations.include?(driver_role)}

    pdf.text "Impiegati",size: 20, font_style: :bold
    office_workers.sort_by{|d| d.person.list_name }.each_with_index do |d,i|
      pdf.table [[pdf.make_cell(content: (i+1).to_s,size: 26, font_style: :bold,height: 27, align: :center, valign: :center),
        pdf.make_table([[pdf.make_cell(content: d.person.list_name,size: 17, font_style: :bold,height: 27,borders: [])],
          [pdf.make_cell(content: d.complete_duration_label,size: 13,borders: [],width: 240),
          pdf.make_cell(content: motivation ? "Per: #{d.leave_code.description.downcase}" : '',size: 13,borders: [],width: 240)]],width: 480)]],

        # pdf.table [pdf.make_table([[pdf.make_cell(content: d.person.list_name,size: 13, font_style: :bold,height: 25)],[pdf.make_cell(content: d.complete_duration_label,size: 26)],],width: 75)],
        # pdf.table [pdf.make_table([[pdf.make_cell(content: d.person.list_name)],[pdf.make_cell(content: d.complete_duration_label)],[pdf.make_cell(content: d.leave_code.description)]])],
        # [pdf.make_cell(content: (i+1).to_s)],
        # :border_style => :grid,
        # :font_size => 11,
        :position => :center,
        :column_widths => { 0 => 60, 1 => 480},
        # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
        :row_colors => ["FFFFFF"]
    end

    pdf.move_down 20

    pdf.text "Operai",size: 20, font_style: :bold
    mechanics.sort_by{|d| d.person.list_name }.each_with_index do |d,i|
      pdf.table [[pdf.make_cell(content: (i+1).to_s,size: 26, font_style: :bold,height: 27, align: :center, valign: :center),
        pdf.make_table([[pdf.make_cell(content: d.person.list_name,size: 17, font_style: :bold,height: 27,borders: [])],
          [pdf.make_cell(content: d.complete_duration_label,size: 13,borders: [],width: 240),
          pdf.make_cell(content: motivation ? "Per: #{d.leave_code.description.downcase}" : '',size: 13,borders: [],width: 240)]],width: 480)]],

        # pdf.table [pdf.make_table([[pdf.make_cell(content: d.person.list_name,size: 13, font_style: :bold,height: 25)],[pdf.make_cell(content: d.complete_duration_label,size: 26)],],width: 75)],
        # pdf.table [pdf.make_table([[pdf.make_cell(content: d.person.list_name)],[pdf.make_cell(content: d.complete_duration_label)],[pdf.make_cell(content: d.leave_code.description)]])],
        # [pdf.make_cell(content: (i+1).to_s)],
        # :border_style => :grid,
        # :font_size => 11,
        :position => :center,
        :column_widths => { 0 => 60, 1 => 480},
        # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
        :row_colors => ["FFFFFF"]
    end

    pdf.move_down 20

    pdf.text "Autisti",size: 20, font_style: :bold
    drivers.sort_by{|d| d.person.list_name }.each_with_index do |d,i|
      pdf.table [[pdf.make_cell(content: (i+1).to_s,size: 26, font_style: :bold,height: 27, align: :center, valign: :center),
        pdf.make_table([[pdf.make_cell(content: d.person.list_name,size: 17, font_style: :bold,height: 27,borders: [])],
          [pdf.make_cell(content: d.complete_duration_label,size: 13,borders: [],width: 240),
          pdf.make_cell(content: motivation ? "Per: #{d.leave_code.description.downcase}" : '',align: :left, size: 13,borders: [], width: 240)]],width: 480)]],

        # pdf.table [pdf.make_table([[pdf.make_cell(content: d.person.list_name,size: 13, font_style: :bold,height: 25)],[pdf.make_cell(content: d.complete_duration_label,size: 26)],],width: 75)],
        # pdf.table [pdf.make_table([[pdf.make_cell(content: d.person.list_name)],[pdf.make_cell(content: d.complete_duration_label)],[pdf.make_cell(content: d.leave_code.description)]])],
        # [pdf.make_cell(content: (i+1).to_s)],
        # :border_style => :grid,
        # :font_size => 11,
        :position => :center,
        :column_widths => { 0 => 60, 1 => 480},
        # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
        :row_colors => ["FFFFFF"]
    end

    pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
    	count = pdf.page_count
    	pdf.text "Page #{count}"
    end

    respond_to do |format|
      format.pdf do
        pdf = pdf
        send_data pdf.render, filename:
        "assenze_#{date.strftime("%Y_%m_%d")}.pdf",
        type: "application/pdf"
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
      @month = (Date.today).strftime("%m").to_i
    else
      @month = params.require('month').to_i+1
    end
    if params[:year].nil?
      @year = (Date.today).strftime("%Y").to_i
    else
      @year = params.require('year').to_i
    end
    if params[:date].nil?
      if params[:day].nil?
        @day = Time.now - 1.days
      else
        @day = Time.strptime(params[:day],"%Y-%m-%d")
      end
    else

      @day = Time.strptime(params[:date],"%Y-%m-%d")
      # @day = Time.now
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

  def get_from_to
    if params[:from].nil?
      @from = Time.now - 3.days
    else
      @from = Time.strptime(params[:from],"%Y-%m-%d")
    end
    if params[:to].nil?
      @to = @from + 2.months
    else
      @to = Time.strptime(params[:to],"%Y-%m-%d")
    end
    if @from > @to
      tmp = @from
      @from = @to
      @to = tmp
    end
  end

  def festivity_params
    params.require(:festivity).permit(:name, :day, :month, :year)
  end

  def leave_code_params
    params.require(:leave_code)['afterhours'] = false if params.require(:leave_code)['afterhours'].nil?
    params.require(:leave_code).permit(:code, :afterhours, :description)
  end

  def working_schedule_params
    p = Hash.new
    params.require(:working_schedule).permit(:weekday, :agreement_from, :agreement_to, :contract_from, :contract_to, :break, :months_unpaid_days, :expected_hours, :flexibility, :agreement)
    p[:person] = @person
    p[:weekday] = params[:working_schedule][:weekday]
    p[:agreement_from_s] = params[:working_schedule][:agreement_from] #== ''? nil :Time.strptime(params[:working_schedule][:agreement_from],"%H:%M")-PresenceController.actual_offset.hours
    p[:agreement_to_s] = params[:working_schedule][:agreement_to]#== ''? nil :Time.strptime(params[:working_schedule][:agreement_to],"%H:%M")-PresenceController.actual_offset.hours
    p[:contract_from_s] = params[:working_schedule][:contract_from] #== ''? nil : Time.strptime(params[:working_schedule][:contract_from],"%H:%M")-PresenceController.actual_offset.hours
    p[:contract_to_s] = params[:working_schedule][:contract_to] #== ''? nil :Time.strptime(params[:working_schedule][:contract_to],"%H:%M")-PresenceController.actual_offset.hours
    p[:break] = params[:working_schedule][:break]
    p[:months_unpaid_days] = params[:working_schedule][:months_unpaid_days]
    p[:expected_hours] = params[:working_schedule][:expected_hours]
    p[:flexibility] = params[:working_schedule][:flexibility]
    p[:agreement] = params[:working_schedule][:agreement] == 'true' ? true : false


    if p[:weekday].nil? || p[:weekday] == ''
      raise "Non è stato impostato il giorno della settimana."
    end
    if p[:months_unpaid_days].nil? || p[:months_unpaid_days] == ""
      raise "Non sono stati impostati i giorni non pagati."
    end
    if p[:expected_hours].nil? || p[:expected_hours] == ""
      raise "Non sono state impostate la ore previste."
    end
    if p[:break].nil? || p[:break] == ""
      raise "Non è stata impostata la pausa."
    end
    if p[:person].nil? || p[:person] == ""
      raise "Non è stato impostato il dipendente."
    end
    if p[:flexibility].nil? || p[:flexibility] == ""
      raise "Non è stata impostata la flessibilità."
    end
    if p[:agreement_from_s].nil? || p[:agreement_to_s].nil? || p[:agreement_from_s] == "" || p[:agreement_to_s] == ""
      raise "L'orario concordato non e' completo."
    end
    if p[:contract_from_s].nil? || p[:contract_to_s].nil? || p[:contract_from_s] == "" || p[:contract_to_s] == ""
      raise "L'orario da contratto non e' completo."
    end
    if p[:contract_from_s].nil? && p[:contract_to_s].nil? && p[:agreement_from_s].nil? && p[:agreement_to_s].nil?
      raise "Non sono stati impostati gli orari."
    end

    if !WorkingSchedule.find_by(weekday: p[:weekday], person: @person).nil? && params[:commit] == 'Inserisci'
      raise "#{@person.list_name} ha già un orario per il #{WorkingSchedule.weekdays.key(p[:weekday].to_i)}."
    end
    p
  end

  def get_tab
    @tab = params['tab']
  end

  def get_scroll
    @scroll = params['scroll']
    @scroll_element = params['scroll_element']
  end

  def self.special_logger
    @@presence_logger ||= Logger.new("#{Rails.root}/log/presence.log")
  end
end
