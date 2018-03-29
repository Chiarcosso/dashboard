class CarwashController < ApplicationController

  def checks_index
    @checks = VehicleCheck.all
    render 'carwash/checks_index'
  end

  def start_check_session
    @check_session = VehicleCheckSession.new
    render :partial => 'carwash/checks_index'
  end

  private

  def get_vehicle
    @vehicle = Vehicle.find(params.require(:vehicle_id))
  end
end
