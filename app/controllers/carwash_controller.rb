class CarwashController < ApplicationController

  before_action :set_station
  before_action :get_check, only: [:last_vehicle_checks_search]
  before_action :get_order, only: [:last_vehicle_checks_search]

  def index
    @carwash_usages = CarwashUsage.lastmonth.order(:ending_time => :desc)
  end

  def checks_index
    @check_sessions = VehicleCheckSession.where(station: 'carwash').opened.order(created_at: :asc)+VehicleCheckSession.where(station: 'carwash').closed.order(finished: :desc).last_week
    render 'carwash/checks_index'
  end

  def vehicle_checks_autocomplete
    unless params[:search].nil? or params[:search] == ''
      # array = Language.filter(params.require(:search))
      search = params.require(:search).gsub("'","''").tr(' ','%')
      # array = VehicleInformationType.find_by_sql("select 'vehicle_information_type' as field, 'Vehicle' as model, c.id as 'vehicle_information_type_id', c.name as label from vehicle_information_types c where c.name like '%#{search}%' and c.vehicle_information_type limit 10")
      array = VehicleCheck.where("vehicle_checks.label like '%#{search}%'").map { |ch| {field: 'search', model: 'VehicleCheck', vehicle_check_id: ch.label, label: ch.label}}

      render :json => array.uniq
    end
  end

  def start_check_session
    begin
      p = params.require('VehicleCheckSession').permit(:model_name,:vehicle_id,:station)

      if p[:model_name] == 'ExternalVehicle'
        v = ExternalVehicle.find(p[:vehicle_id])
        vec = v.vehicle_checks(p[:station])
        if vec.size < 1
          raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
        end
        odl = VehicleCheckSession.create_worksheet(current_user,v)

        @worksheet = Worksheet.create(code: "EWC*#{res}", vehicle: v, vehicle_type: v.class.to_s, opening_date: Date.current, station: @station.to_s)
        @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: v, operator: current_user, theoretical_duration: v.vehicle_checks(p[:station]).map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: odl, worksheet: @worksheet, station: @station.to_s)
      elsif p[:model_name] == 'Vehicle'
        v = Vehicle.find(p[:vehicle_id])
        vec = v.vehicle_checks(p[:station])
        if vec.size < 1
          raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
        end
        odl = VehicleCheckSession.create_worksheet(current_user,v,'PUNTO CHECK-UP','55','Controlli')

        @worksheet = Worksheet.create(code: "EWC*#{odl}", vehicle: v, vehicle_type: v.class.to_s, opening_date: Date.current, station: @station.to_s)
        @check_session = VehicleCheckSession.create(date: Date.today,vehicle: v, operator: current_user, theoretical_duration: v.vehicle_checks(p[:station]).map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: odl, worksheet: @worksheet, station: @station.to_s)
      else
        raise "Veicolo non specificato (#{p[:model_name].inspect})"
      end
      @checks = Hash.new

      vec.each do |vc|
        @checks[vc.code] = Array.new if @checks[vc.code].nil?
        @checks[vc.code] << VehiclePerformedCheck.create(vehicle_check_session: @check_session, vehicle_check: vc, value: nil, notes: nil, performed: 0, mandatory: v.mandatory?(vc) )
      end


      respond_to do |format|
        format.js { render :partial => 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n"+e.backtrace.join("\n")
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def continue_check_session
    begin
      @check_session = VehicleCheckSession.find(params.require(:id))
      @check_session.update(log: @check_session.log.to_s+"\nSessione ripresa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")
      @checks = @check_session.vehicle_ordered_performed_checks
      respond_to do |format|
        format.js { render :partial => 'workshop/worksheet_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def update_vehicle_check
    begin
      @tab = params['tab']
      pc = VehiclePerformedCheck.find(params.require(:field)[/check\[(\d*)\]\[.*\]$/,1].to_i)
      case params.require(:field)[/check\[\d*\]\[(.*)\]$/,1]
      when 'value' then
        pc.update(value: params.require(:value), time: DateTime.now, user: current_user)
      when 'notes' then
        pc.update(notes: params.require(:value), user: current_user)
      when 'performed' then
        pc.update(performed: params.require(:value).to_i, user: current_user, time: DateTime.now)
      end
      @line = "##{pc.id}"
      @check_session = pc.vehicle_check_session
      @check_session.update(real_duration: params.require(:additional))
      @checks = @check_session.vehicle_ordered_performed_checks
      if params['station'] == 'carwash'
        @station = 'carwash'
      else
        @station = 'workshop'
      end
      # pc.create_notification(current_user)
      respond_to do |format|
        # case @station
        # when 'workshop' then
          @worksheet = @check_session.worksheet
          @worksheet.update(real_duration: params.require(:additional))
          @protocol = 'checks'
          # @station = 'workshop'
          format.js { render partial: 'workshop/worksheet_js' }
        # when 'carwash' then
        #   # format.js { render partial: 'carwash/checks_js' }
        #   format.js { render partial: 'workshop/worksheet_js' }
        # end
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def save_check_session
    begin

      @check_session = VehicleCheckSession.find(params.require(:id))

      if @check_session.myofficina_reference.nil?

        odl = VehicleCheckSession.create_worksheet(current_user,@check_session.vehicle,'PUNTO CHECK-UP','55','Controlli')
        @check_session.update(myofficina_reference: odl, worksheet: Worksheet.create(code: "EWC*#{odl}", vehicle: @check_session.vehicle, vehicle_type: @check_session.vehicle.class.to_s, opening_date: Date.current, station: @station))

      end


      @check_session.update(finished: DateTime.now, real_duration: params.require(:time), log: @check_session.log.to_s+"\nSessione conclusa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")

      @check_session.close_worksheet(current_user)

      if @check_session.vehicle_performed_checks.not_ok.count > 0
        begin
          CarwashMailer.check_up(@check_session).deliver_now
          puts
          puts'Mail sent.'
          puts
        rescue EOFError,
                IOError,
                Errno::ECONNRESET,
                Errno::ECONNABORTED,
                Errno::EPIPE,
                Errno::ETIMEDOUT,
                Net::SMTPAuthenticationError,
                Net::SMTPServerBusy,
                Net::SMTPSyntaxError,
                Net::SMTPUnknownError,
                OpenSSL::SSL::SSLError => e
          puts
          puts 'An error occurred sending mail..'
          puts  e.inspect
          puts
          self.reset_status
        end
      end

      respond_to do |format|
        # format.js { render :partial => 'carwash/checks_js' }
        format.js { render 'carwash/checks_index_js' }
      end
    rescue Exception => e
      @error = e.message+e.backtrace.join("\n")
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def delete_check_session
    begin
      VehicleCheckSession.find(params.require(:id)).destroy
      respond_to do |format|
        # format.js { render :partial => 'carwash/checks_js' }
        format.js { render 'carwash/checks_index_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def last_vehicle_checks
    respond_to do |format|
      format.html { render 'carwash/last_vehicle_checks_index' }
    end
  end

  def last_vehicle_checks_search
    begin
      respond_to do |format|
        format.js { render :partial => 'carwash/last_vehicle_checks_js' }
      end
    rescue Exception => e
      @error = e.message+"\n\n#{e.backtrace}"
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private

  def get_vehicle
    @vehicle = Vehicle.find(params.require(:vehicle_id))
  end

  def set_station
    @station = params['station'].nil? ? 'carwash' : params['station']
  end

  def start_session_params

  end

  def get_check
    @checks = VehicleCheck.where("label = ?",params.require('check').permit(:label)[:label])
  end

  def get_order
    # @order = params['order']
    # @ordering = params['ordering']
  end
end
