class VehicleEquipmentsController < ApplicationController

  before_action :set_vehicle_equipment, only: [:show, :edit, :update, :destroy]


  def index
    @vehicle_typologies = VehicleEquipment.all
  end


  def show
  end

  def new
    @vehicle_equipment = VehicleEquipment.new
  end

  def edit
    respond_to do |format|
      format.js { render :partial => 'vehicle_equipments/form' }
    end
  end

  def create
    p = vehicle_equipment_params
    @vehicle_equipment = VehicleEquipment.create(p) if @vehicle_equipment.nil?
    respond_to do |format|
      format.js { render :partial => 'vehicle_equipments/form' }
    end
  end

  def update
    @vehicle_equipment.update(params.require(:vehicle_equipment).permit(:name))
    @vehicle_equipment.vehicle_types.clear
    unless params[:vehicle_equipment_types].nil?
      params.require(:vehicle_equipment_types).each do |vt|
        @vehicle_equipment.vehicle_types << VehicleType.find(vt.to_i)
      end
    end
    @vehicle_equipment.vehicle_typologies.clear
    unless params[:vehicle_equipment_typologies].nil?
      params.require(:vehicle_equipment_typologies).each do |ve|
        @vehicle_equipment.vehicle_typologies << VehicleTypology.find(ve.to_i)
      end
    end
    # @vehicle_equipment.vehicle_information_types.clear
    # unless params[:vehicle_equipment_information_types].nil?
    #   params.require(:vehicle_equipment_information_types).each do |vi|
    #     @vehicle_equipment.vehicle_information_types << VehicleInformationType.find(vi.to_i)
    #   end
    # end
    # redirect_to '/vehicle_types#tab-equipment'
    respond_to do |format|
      format.js { render :partial => 'vehicle_equipments/list_js' }
    end

  end

  def destroy
    begin
      @vehicle_equipment.destroy
    rescue Exception => e
      @error = "Impossibile eliminare l'attrezzatura: #{@vehicle_equipment.name}.\n\n#{e.message}"
    end
    respond_to do |format|
      format.js { render :partial => 'vehicle_equipments/list_js' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_equipment
      @vehicle_equipment = VehicleEquipment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_equipment_params
      p = params.require(:vehicle_equipment).permit(:name)
      p[:name].capitalize!
      @vehicle_equipment = VehicleEquipment.find_by_name(p[:name])
      p
    end
end
