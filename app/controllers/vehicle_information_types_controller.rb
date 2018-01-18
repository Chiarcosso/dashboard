class VehicleInformationTypesController < ApplicationController

  before_action :set_vehicle_information_type, only: [:show, :edit, :update, :destroy]


  def index
    @vehicle_typologies = VehicleInformationType.all
  end


  def show
  end

  def new
    @vehicle_information_type = VehicleInformationType.new
  end

  def edit
    respond_to do |format|
      format.js { render :partial => 'vehicle_information_types/form' }
    end
  end

  def create
    p = vehicle_information_type_params
    @vehicle_information_type = VehicleInformationType.create(p) if @vehicle_information_type.nil?
    respond_to do |format|
      format.js { render :partial => 'vehicle_information_types/form' }
    end
  end

  def update
    @vehicle_information_type.update(vehicle_information_type_params)
    @vehicle_information_type.vehicle_types.clear
    unless params[:vehicle_information_type_types].nil?
      params.require(:vehicle_information_type_types).each do |vt|
        @vehicle_information_type.vehicle_types << VehicleType.find(vt.to_i)
      end
    end
    @vehicle_information_type.vehicle_typologies.clear
    unless params[:vehicle_information_type_typologies].nil?
      params.require(:vehicle_information_type_typologies).each do |ve|
        @vehicle_information_type.vehicle_typologies << VehicleTypology.find(ve.to_i)
      end
    end
    # @vehicle_information_type.vehicle_information_types.clear
    # unless params[:vehicle_information_type_information_types].nil?
    #   params.require(:vehicle_information_type_information_types).each do |vi|
    #     @vehicle_information_type.vehicle_information_types << VehicleInformationType.find(vi.to_i)
    #   end
    # end
    # redirect_to '/vehicle_types#tab-information_type'
    respond_to do |format|
      format.js { render :partial => 'vehicle_information_types/list_js' }
    end

  end

  def destroy
    begin
      @vehicle_information_type.destroy
    rescue Exception => e
      @error = "Impossibile eliminare il dettaglio mezzi: #{@vehicle_information_type.name}.\n\n#{e.message}"
    end
    respond_to do |format|
      format.js { render :partial => 'vehicle_information_types/list_js' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_information_type
      @vehicle_information_type = VehicleInformationType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_information_type_params
      p = params.require(:vehicle_information_type).permit(:name,:data_type)
      p[:name].capitalize!
      p[:data_type] = p[:data_type].to_i
      @vehicle_information_type = VehicleInformationType.find_by_name(p[:name]) if @vehicle_information_type.nil?
      p
    end
end
