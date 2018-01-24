class VehicleInformationsController < ApplicationController
  before_action :set_vehicle_information, only: [:show, :edit, :update, :destroy]

  # GET /vehicle_informations
  # GET /vehicle_informations.json
  def index
    @vehicle_informations = VehicleInformation.all
  end

  # GET /vehicle_informations/1
  # GET /vehicle_informations/1.json
  def show
  end

  # GET /vehicle_informations/new
  def new
    @vehicle_information = VehicleInformation.new
  end

  # GET /vehicle_informations/1/edit
  def edit
  end

  # POST /vehicle_informations
  # POST /vehicle_informations.json
  def create
    
  end

  # PATCH/PUT /vehicle_informations/1
  # PATCH/PUT /vehicle_informations/1.json
  def update
    respond_to do |format|
      if @vehicle_information.update(vehicle_information_params)
        format.html { redirect_to @vehicle_information, notice: 'Vehicle information was successfully updated.' }
        format.json { render :show, status: :ok, location: @vehicle_information }
      else
        format.html { render :edit }
        format.json { render json: @vehicle_information.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vehicle_informations/1
  # DELETE /vehicle_informations/1.json
  def destroy
    begin
      @vehicle_information.destroy
    rescue Exception => e
      @error += "Impossibile eliminare l'informazione.\n\n#{e.message}"
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicles/vehicle_informations_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_information
      begin
        @vehicle_information = VehicleInformation.find(params[:id])
      rescue Exception => e
        @error += "Impossibile trovare l'informazione (id: #{params[:id]}).\n\n#{e.message}"
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_information_params
      params.require(:vehicle_information).permit(:vehicle_id, :information_type, :information, :date)
    end
end
