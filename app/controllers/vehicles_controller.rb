class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]

  # GET /vehicles
  # GET /vehicles.json
  def index
    @vehicles = Vehicle.all
  end

  # GET /vehicles/1
  # GET /vehicles/1.json
  def show
  end

  # GET /vehicles/new
  def new
    @vehicle = Vehicle.new
  end

  # GET /vehicles/1/edit
  def edit
  end

  # POST /vehicles
  # POST /vehicles.json
  def create
    @vehicle = Vehicle.new(vehicle_params)
    # unless @model.nil? || @property.nil?
      @vehicle.property = @property
      @vehicle.model = @model
    # end
    respond_to do |format|
      if @vehicle.save && !@property.nil? && !@model.nil?
        @vehicle.vehicle_informations << VehicleInformation.create(information: @plate, information_type: VehicleInformation.types['Targa'])
        @vehicle.vehicle_informations << VehicleInformation.create(information: @serial, information_type: VehicleInformation.types['N. di telaio'])
        format.html { redirect_to vehicles_path, notice: 'Vehicle was successfully created.' }
        format.json { render :show, status: :created, location: @vehicle }
      else
        format.html { render :new }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vehicles/1
  # PATCH/PUT /vehicles/1.json
  def update
    respond_to do |format|
      if @vehicle.update(vehicle_params)
        unless @vehicle.plate == @plate
          @vehicle.vehicle_informations << VehicleInformation.create(information: @plate, information_type: VehicleInformation.types['Targa'])
        end
        unless @vehicle.chassis_number == @serial
          @vehicle.vehicle_informations << VehicleInformation.create(information: @serial, information_type: VehicleInformation.types['N. di telaio'])
        end
        format.html { redirect_to vehicles_path, notice: 'Vehicle was successfully updated.' }
        format.json { render :show, status: :ok, location: @vehicle }
      else
        format.html { render :edit }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vehicles/1
  # DELETE /vehicles/1.json
  def destroy
    @vehicle.destroy
    respond_to do |format|
      format.html { redirect_to vehicles_url, notice: 'Vehicle was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle
      @vehicle = Vehicle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_params
      @plate = params.require(:initial_plate).permit(:info)[:info]
      @serial = params.require(:initial_serial).permit(:info)[:info]
      @model = VehicleModel.find(params.require(:vehicle).permit(:model)[:model].to_i)
      @property = Company.where(name: params.require(:vehicle).permit(:property)[:property]).first
      params.require(:vehicle).permit(:dismissed, :registration_date, :initial_serial, :mileage)
      # params.require(:vehicle)[:model] = VehicleModel.find(params.require(:vehicle)[:model].to_i)
      # params
    end
end
