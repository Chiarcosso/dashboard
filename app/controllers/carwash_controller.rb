class CarwashController < ApplicationController

  def checks_index
    @check_sessions = VehicleCheckSession.opened+VehicleCheckSession.closed
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
        @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: v, operator: current_user.person, theoretical_duration: v.vehicle_checks(p[:station]).map{ |c| c.duration }.inject(0,:+))
      elsif p[:model_name] == 'Vehicle'
        v = Vehicle.find(p[:vehicle_id])
        vec = v.vehicle_checks(p[:station])
        if vec.size < 1
          raise "Non ci sono controlli da fare per questo mezzo (targa: #{v.plate})."
        end
        @check_session = VehicleCheckSession.create(date: Date.today,vehicle: v, operator: current_user.person, theoretical_duration: v.vehicle_checks(p[:station]).map{ |c| c.duration }.inject(0,:+))
      else
        raise "Veicolo non specificato (#{p[:model_name].inspect})"
      end
      @checks = Array.new

      vec.each do |vc|
        @checks << VehiclePerformedCheck.create(vehicle_check_session: @check_session, vehicle_check: vc, value: nil, notes: nil, performed: false)
      end
      respond_to do |format|
        format.js { render :partial => 'carwash/checks_js' }
      end
    rescue Exception => e
      @error = e.message#+"\n\n"+e.backtrace.to_s
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def continue_check_session
    begin
      @check_session = VehicleCheckSession.find(params.require(:id))
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

  def update_vehicle_check
    begin
      pc = VehiclePerformedCheck.find(params.require(:field)[/check\[(\d*)\]\[.*\]$/,1].to_i)
      case params.require(:field)[/check\[\d*\]\[(.*)\]$/,1]
      when 'value' then
        pc.update(value: params.require(:value), time: DateTime.now, performed: true)
      when 'notes' then
        pc.update(notes: params.require(:value))
      when 'performed' then
        pc.update(performed: (params.require(:value).downcase == 'true' ? true : false))
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
      VehicleCheckSession.find(params.require(:id)).update(finished: DateTime.now, real_duration: params.require(:time))
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
