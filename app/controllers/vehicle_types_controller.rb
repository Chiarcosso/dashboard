class VehicleTypesController < ApplicationController

  before_action :get_vehicle_type, only: [:update,:destroy,:edit]
  def index
  end

  def new
    @vehicle_type = VehicleType.new
  end

  def edit
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/form' }
    end
  end

  def create
    p = vehicle_type_params
    @vehicle_type = VehicleType.create(p) if @vehicle_type.nil?
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/form' }
    end
  end

  def update
    @vehicle_type.update(params.require(:vehicle_type).permit(:name, :carwash_type))
    @vehicle_type.vehicle_typologies.clear
    unless params[:vehicle_type_typologies].nil?
      params.require(:vehicle_type_typologies).each do |vtt|
        @vehicle_type.vehicle_typologies << VehicleTypology.find(vtt.to_i)
      end
    end
    @vehicle_type.vehicle_equipments.clear
    unless params[:vehicle_type_equipments].nil?
      params.require(:vehicle_type_equipments).each do |ve|
        @vehicle_type.vehicle_equipments << VehicleEquipment.find(ve.to_i)
      end
    end
    @vehicle_type.vehicle_information_types.clear
    unless params[:vehicle_type_information_types].nil?
      params.require(:vehicle_type_information_types).each do |vi|
        @vehicle_type.vehicle_information_types << VehicleInformationType.find(vi.to_i)
      end
    end
    # respond_to do |format|
    #   format.html { redirect_to  'vehicle_types/index' }
    # end
    # redirect_to '/vehicle_types'
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/list_js' }
    end
  end

  def destroy
    begin
      @vehicle_type.destroy
    rescue Exception => e
      @error = "Impossibile eliminare tipo di mezzo: #{@vehicle_type.name}.\n\n#{e.message}"
    end
    respond_to do |format|
      format.js { render :partial => 'vehicle_types/list_js' }
    end
  end

  private

  def get_vehicle_type
    @vehicle_type = VehicleType.find(params.require(:id)) unless params[:id] == 0
  end

  def vehicle_type_params
    p = params.require(:vehicle_type).permit(:name,:carwash_type)
    p[:name].capitalize!
    @vehicle_type = VehicleType.find_by_name(p[:name])
    p
  end
end
