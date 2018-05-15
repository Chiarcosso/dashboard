class CarwashController < ApplicationController

  def index
    @carwash_usages = CarwashUsage.lastmonth.order(:ending_time => :desc)
  end

  def checks_index
    @check_sessions = VehicleCheckSession.opened.order(created_at: :asc)+VehicleCheckSession.closed.order(finished: :desc).last_week
    render 'carwash/checks_index'
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

        @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: v, operator: current_user, theoretical_duration: v.vehicle_checks(p[:station]).map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: odl, worksheet: Worksheet.create(code: "EWC*#{res}", vehicle: v, vehicle_type: v.class.to_s, opening_date: Date.current))
      elsif p[:model_name] == 'Vehicle'
        v = Vehicle.find(p[:vehicle_id])
        vec = v.vehicle_checks(p[:station])
        if vec.size < 1
          raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
        end
        odl = VehicleCheckSession.create_worksheet(current_user,v)

        @check_session = VehicleCheckSession.create(date: Date.today,vehicle: v, operator: current_user, theoretical_duration: v.vehicle_checks(p[:station]).map{ |c| c.duration }.inject(0,:+), log: "Sessione iniziata da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.", myofficina_reference: odl, worksheet: Worksheet.create(code: "EWC*#{odl}", vehicle: v, vehicle_type: v.class.to_s, opening_date: Date.current))
      else
        raise "Veicolo non specificato (#{p[:model_name].inspect})"
      end
      @checks = Hash.new

      vec.each do |vc|
        @checks[vc.code] = Array.new if @checks[vc.code].nil?
        @checks[vc.code] << VehiclePerformedCheck.create(vehicle_check_session: @check_session, vehicle_check: vc, value: nil, notes: nil, performed: 0, mandatory: v.mandatory?(vc) )
      end


      respond_to do |format|
        format.js { render :partial => 'carwash/checks_js' }
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
        format.js { render :partial => 'carwash/checks_js' }
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
      respond_to do |format|
        format.js { render :partial => 'carwash/checks_js' }
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
        
        odl = VehicleCheckSession.create_worksheet(current_user,@check_session.vehicle)
        @check_session.update(myofficina_reference: odl, worksheet: Worksheet.create(code: "EWC*#{odl}", vehicle: @check_session.vehicle, vehicle_type: @check_session.vehicle.class.to_s, opening_date: Date.current))

      end


      @check_session.update(finished: DateTime.now, real_duration: params.require(:time), log: @check_session.log.to_s+"\nSessione conclusa da #{current_user.person.complete_name}, il #{Date.today.strftime('%d/%m/%Y')} alle #{DateTime.now.strftime('%H:%M:%S')}.")

      @check_session.close_worksheet(current_user)

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
  private

  def get_vehicle
    @vehicle = Vehicle.find(params.require(:vehicle_id))
  end

  def start_session_params

  end
end
