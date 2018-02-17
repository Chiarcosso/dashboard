class ExternalVehiclesController < ApplicationController
  before_action :set_external_vehicle, only: [:show, :edit, :update, :destroy]

  def json_autocomplete_plate
    r = ExternalVehicle.where("plate like '%#{params.require(:search)}%'").map { |ev| [{value: ev.plate, width: 2},{value: ev.owner.name, width: 3},{value: ev.vehicle_type.name, width: 2},{value: ev.vehicle_typology.name, width: 3}] }
    render :json => r.to_json
  end

  def index
    # @external_vehicles = ExternalVehicle.all
    render 'external_vehicles/_index'
  end

  # GET /external_vehicles/1
  # GET /external_vehicles/1.json
  def show
  end

  # GET /external_vehicles/new
  def new
    @external_vehicle = ExternalVehicle.new
  end

  # GET /external_vehicles/1/edit
  def edit
  end

  # POST /external_vehicles
  # POST /external_vehicles.json
  def create
    begin
      ExternalVehicle.create(external_vehicle_params)
    rescue Exception => e
      @error = "#{e.message}"
    end

    respond_to do |format|
      if @error.nil?
        format.js { render partial: 'external_vehicles/index_js'}
      else
        format.js { render partial: 'layouts/error'}
      end
    end
  end

  # PATCH/PUT /external_vehicles/1
  # PATCH/PUT /external_vehicles/1.json
  def update
    respond_to do |format|
      if @external_vehicle.update(external_vehicle_params)
        format.html { redirect_to @external_vehicle, notice: 'External vehicle was successfully updated.' }
        format.json { render :show, status: :ok, location: @external_vehicle }
      else
        format.html { render :edit }
        format.json { render json: @external_vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /external_vehicles/1
  # DELETE /external_vehicles/1.json
  def destroy
    @external_vehicle.destroy
    respond_to do |format|
      format.html { redirect_to external_vehicles_url, notice: 'External vehicle was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_external_vehicle
      @external_vehicle = ExternalVehicle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def external_vehicle_params
      params.require(:external_vehicle).permit(:owner_id, :plate, :vehicle_type_id, :vehicle_typology_id)
    end
end
