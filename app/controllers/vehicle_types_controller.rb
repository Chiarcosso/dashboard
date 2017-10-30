class VehicleTypesController < ApplicationController

  before_action :get_vehicle_type, only: [:update,:destroy]
  def index
  end

  def new
    @vehicle_type = VehicleType.new
  end

  def edit
    @vehicle_type = VehicleType.find(params.require(:id))
  end

  def create
    VehicleType.create(params.require(:vehicle_type).permit(:name, :carwash_type))
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/list_js' }
    end
  end

  def update
    @vehicle_type.update(params.require(:vehicle_type).permit(:name, :carwash_type))
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/list_js' }
    end
    # render 'index'
  end

  def destroy
    @vehicle_type.destroy
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/list_js' }
    end
  end

  private

  def get_vehicle_type
    @vehicle_type = VehicleType.find(params.require(:id))
  end
end
