class VehicleTypologiesController < ApplicationController

  before_action :set_vehicle_typology, only: [:show, :edit, :update, :destroy]

  # GET /vehicle_typologies
  # GET /vehicle_typologies.json
  def index
    @vehicle_typologies = VehicleTypology.all
  end

  # GET /vehicle_typologies/1
  # GET /vehicle_typologies/1.json
  def show
  end

  # GET /vehicle_typologies/new
  def new
    @vehicle_typology = VehicleTypology.new
  end

  # GET /vehicle_typologies/1/edit
  def edit
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/form' }
    end
  end

  # POST /vehicle_typologies
  # POST /vehicle_typologies.json
  def create
    p = vehicle_typology_params
    @vehicle_typology = VehicleTypology.create(p) if @vehicle_typology.nil?
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/form' }
    end
  end

  # PATCH/PUT /vehicle_typologies/1
  # PATCH/PUT /vehicle_typologies/1.json
  def update
    @vehicle_typology.update(params.require(:vehicle_typology).permit(:name))
    @vehicle_typology.vehicle_types.clear
    unless params[:vehicle_typology_types].nil?
      params.require(:vehicle_typology_types).each do |vt|
        @vehicle_typology.vehicle_types << VehicleType.find(vt.to_i)
      end
    end
    @vehicle_typology.vehicle_equipments.clear
    unless params[:vehicle_typology_equipments].nil?
      params.require(:vehicle_typology_equipments).each do |ve|
        @vehicle_typology.vehicle_equipments << VehicleEquipment.find(ve.to_i)
      end
    end
    @vehicle_typology.vehicle_information_types.clear
    unless params[:vehicle_typology_information_types].nil?
      params.require(:vehicle_typology_information_types).each do |vi|
        @vehicle_typology.vehicle_information_types << VehicleInformationType.find(vi.to_i)
      end
    end
    # respond_to do |format|
    #   format.html { redirect_to  'vehicle_types/index' }
    # end
    # redirect_to '/vehicle_types#tab-typology'
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/list_js' }
    end
    # @vehicle_typology.update(vehicle_typology_params)
    # respond_to do |format|
    #   format.js { render :partial => 'vehicle_typologies/list_js' }
    # end
  end

  # DELETE /vehicle_typologies/1
  # DELETE /vehicle_typologies/1.json
  def destroy
    begin
      @vehicle_typology.destroy
    rescue Exception => e
      @error = "Impossibile eliminare tipologia di mezzo: #{@vehicle_typology.name}.\n\n#{e.message}"
    end
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/list_js', notice: @error }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_typology
      @vehicle_typology = VehicleTypology.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_typology_params
      p = params.require(:vehicle_typology).permit(:name)
      p[:name].capitalize!
      @vehicle_typology = VehicleTypology.find_by_name(p[:name])
      p
    end
end
