class CodesController < ApplicationController

  before_action :authenticate_user!

  def index
  end

  def new_carwash_driver_code
    if @code.nil?
      CarwashDriverCode.create(code: params.require(:code))
      # @msg = 'Codice creato.'
    else
      # @msg = 'Codice esistente.'
    end
    respond_to do |f|
      format.js { render :partial => 'codes/drivers_codes' }
    end
  end

  private

  def get_driver_code
    @code = CarwashDriverCode.findByCode(params.require(:code))
  end
end
