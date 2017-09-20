class VehicleTypesController < ApplicationController

  before_action :get_vehicle_type, only: [:update]
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
    render 'index'
  end

  def update
    @vehicle_type.update(params.require(:vehicle_type).permit(:name, :carwash_type))
    render 'index'
  end

  def delete
  end

  private

  def get_vehicle_type
    @vehicle_type = VehicleType.find(params.require(:id))
  end
end
