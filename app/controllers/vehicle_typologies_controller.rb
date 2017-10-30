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
  end

  # POST /vehicle_typologies
  # POST /vehicle_typologies.json
  def create
    @vehicle_typology = VehicleTypology.create(vehicle_typology_params)
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/list_js' }
    end
  end

  # PATCH/PUT /vehicle_typologies/1
  # PATCH/PUT /vehicle_typologies/1.json
  def update
    @vehicle_typology.update(vehicle_typology_params)
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/list_js' }
    end
  end

  # DELETE /vehicle_typologies/1
  # DELETE /vehicle_typologies/1.json
  def destroy
    @vehicle_typology.destroy
    respond_to do |format|
      format.js { render :partial => 'vehicle_typologies/list_js' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_typology
      @vehicle_typology = VehicleTypology.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_typology_params
      params.require(:vehicle_typology).permit(:name)
    end
end
