class CarwashController < ApplicationController

  def checks_index
    @checks = VehicleCheck.all
    render 'carwash/checks_index'
  end

  def start_check_session
    begin
      p = params.require('VehicleCheckSession').permit(:model_name,:vehicle_id)
      if p[:model_name] == 'ExternalVehicle'
        ev = ExternalVehicle.find(p[:vehicle_id])
        @check_session = VehicleCheckSession.create(date: Date.today,external_vehicle: ev, operator: current_user.person, theoretical_duration: ev.vehicle_checks.inject('+',0))
      elsif p[:model_name] == 'Vehicle'
        v = Vehicle.find(p[:vehicle_id])
        @check_session = VehicleCheckSession.create(date: Date.today,vehicle: v, operator: current_user.person, theoretical_duration: v.vehicle_checks.inject('+',0))
      else
        raise "Veicolo non specificato (#{p[:model_name].inspect})"
      end
      render :partial => 'carwash/checks_index'
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
