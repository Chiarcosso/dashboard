class PresenceController < ApplicationController

  before_action :get_person
  before_action :get_working_schedule, only: [:edit_working_schedule, :delete_working_schedule]

  def manage
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

  def self.read_timestamps(opts = {:get_all => true})
    #set starting date
    if opts[:get_all]
      year = 2014
      month = 1
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
      last_timestamp = PresenceTimestamp.real_timestamps.order(timestamp: :desc).first
      if last_timestamp.nil?
        year = 2014
        month = 1
      else
        year = last_timestamp.timestamp.strftime("%Y").to_i
        month = last_timestamp.timestamp.strftime("%m").to_i
      end
    end
    fname = "#{ENV['RAILS_CAME_PATH']}Sto#{month.to_s.rjust(2,'0')}#{year}.sto"
    byebug
    while File.exist?("#{ENV['RAILS_CAME_PATH']}Sto#{month.to_s.rjust(2,'0')}#{year}.sto") do
      rf = File.read(fname).force_encoding('iso-8859-1')
      row = 1
      # rf.scan(/.*\((.*)\)[\x01](\d*)[\x01]([\d \:\/]*)[\x01]/) do |badge,sensor,timestamp|
      rf.scan(/\d+\x01+\d+\x01\D*([A-Za-z]?\d)\D*\x01+(\d*)\x01+([\d \:\/]*)\x01+/) do |badge,sensor,timestamp|
        b = Badge.find_or_create(badge.gsub(/\s+/,''))
        ts = PresenceTimestamp.find_or_create(badge: b, sensor: sensor, time: DateTime.strptime(timestamp,"%d/%m/%y %H:%M:%S"),row: row, file: fname)
        puts ts
        row += 1
      end
      month += 1
      if month > 12
        month = 1
        year += 1
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
end
