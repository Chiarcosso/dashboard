class PresenceController < ApplicationController

  before_action :get_person
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
      byebug
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
      byebug
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def self.read_timestamps(opts = {:get_current => true})
    #set starting date
    if opts[:get_all]
      year = 2014
      month = 4
    elsif opts[:get_current]
      last_timestamp = PresenceTimestamp.real_timestamps.order(time: :desc).first
      year = last_timestamp.time.strftime("%Y").to_i
      month = last_timestamp.time.strftime("%m").to_i
    elsif !opts[:month].nil? && !opts[:year].nil?
      if opts[:year] < 2014
        year = 2014
      else
        year = opts[:year]
      end
      if opts[:month] != 12
        month = opts[:month]%12
      else
        month = 12
      end
    else
      last_timestamp = PresenceTimestamp.real_timestamps.order(time: :desc).first
      if last_timestamp.nil?
        year = 2014
        month = 4
      else
        year = last_timestamp.times.strftime("%Y").to_i
        month = last_timestamp.time.strftime("%m").to_i
      end
    end

    #first filename
    fname = "#{ENV['RAILS_CAME_PATH']}Sto#{month.to_s.rjust(2,'0')}#{year}.sto"
    # fname = "Sto#{month.to_s.rjust(2,'0')}#{year}.sto"
    # smbc = Rsmbclient.new(host: 'AC83',share: 'Rbm84', user: ENV['RAILS_SMB_USER'], password: ENV['RAILS_SMB_PASS'])
    # smbc.cd('Rbm84\Storico')
    # byebug

    #while the next file exists read it and store information
    if File.exist?(fname)

      fh = File.open(fname)
      rf = fh.read.force_encoding('iso-8859-1')
      row = 1

      rf.scan(/\d+\x01+\d+\x01+.*\( *([A-Za-z]?\d*) *\).*\x01+(\d*)\x01+([\d \:\/]*)\x01+/) do |badge,sensor,timestamp|
        if last_timestamp.nil? || (opts[:get_current] && last_timestamp.time < DateTime.strptime(timestamp,"%d/%m/%y %H:%M:%S"))
          b = Badge.find_or_create(badge.gsub(/\s+/,''))
          s = Sensor.find_by(number: sensor.to_i)
          ts = PresenceTimestamp.find_or_create(badge: b, sensor: s, time: DateTime.strptime(timestamp,"%d/%m/%y %H:%M:%S"),row: row, file: fname)
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
    if params['person'].nil?
      @person = Person.order(:surname).first
    else
      @person = Person.find(params.require(:person).to_i)
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
    params.require(:leave_code).permit(:code, :afterhours)
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
end
