class CarwashController < ApplicationController

  def checks_index
    @checks = VehicleCheck.all
    render 'carwash/checks_index'
  end

  def start_check_session
    byebug
    p = params.require(:vehicle_check_session).permit(:model_name,:vehicle_id)
    @check_session = VehicleCheckSession.new
    render :partial => 'carwash/checks_index'
  end

  private

  def get_vehicle
    @vehicle = Vehicle.find(params.require(:vehicle_id))
  end

  def start_session_params

  end
end
