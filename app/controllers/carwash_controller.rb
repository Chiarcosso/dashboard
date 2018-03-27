class CarwashController < ApplicationController

  def checks_index
    @checks = VehicleCheck.all
    render 'carwash/checks_index'
  end

end
