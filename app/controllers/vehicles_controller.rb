class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy, :vehicle_information_type_autocomplete, :get_info, :get_workshop_info]
  before_action :search_params
  autocomplete :vehicle, :plate, full: true


  def vehicle_information_type_autocomplete
    unless params[:search].nil? or params[:search] == ''
      # array = Language.filter(params.require(:search))
      search = params.require(:search).tr(' ','%')
      # array = VehicleInformationType.find_by_sql("select 'vehicle_information_type' as field, 'Vehicle' as model, c.id as 'vehicle_information_type_id', c.name as label from vehicle_information_types c where c.name like '%#{search}%' and c.vehicle_information_type limit 10")
      array = @vehicle.possible_information_types.map { |it| {field: 'vehicle_information_type', model: 'Vehicle', vehicle_information_type_id: it.id, label: it.name}}
      render :json => array
    end
  end

  def get_info
    respond_to do |format|
      format.js { render :partial => 'vehicles/infobox' }
    end
  end

  def get_workshop_info
    respond_to do |format|
      format.js { render :partial => 'vehicles/infobox_workshop' }
    end
  end

  def index

    @vehicles = Vehicle.filter(@search).sort_by { |v| v.plate } unless @search.nil?#.paginate(:page => params[:page], :per_page => 30)

    respond_to do |format|
      format.html { render 'vehicles/index', notice: @notice}
    end
  end

  # GET /vehicles/1
  # GET /vehicles/1.json
  def show
  end

  # GET /vehicles/new
  def new
    @vehicle = Vehicle.new
    @vehicle.model = VehicleModel.not_available
    @vehicle.vehicle_type = VehicleType.not_available
    @vehicle.vehicle_typology = VehicleTypology.not_available
    @vehicle.registration_date = Date.today
    @vehicle_types = VehicleType.all
    @vehicle_typologies = VehicleTypology.all
    @information_types = VehicleInformationType.all
    @gear = Gear.order(:name)
    @equipment = VehicleEquipment.order(:name)
  end

  # POST /vehicles/edit
  def edit
    @vehicle_types = VehicleType.all
    @vehicle_typologies = VehicleTypology.all
    # @information_types = VehicleInformationType.all
    @informations = @vehicle.vehicle_informations - [@vehicle.last_information(VehicleInformationType.plate),@vehicle.last_information(VehicleInformationType.chassis)]
    @informations.sort_by! { |i| i.vehicle_information_type.name }
    # @informations = info + @vehicle.possible_informations.map { |i| VehicleInformation.new(vehicle: @vehicle, information_type: i, date: Date.current) unless info.map { |vi| vi.information_type }.include?(i)  }
    @gear = Gear.order(:name)
    @equipment = VehicleEquipment.order(:name)
    respond_to do |format|
      format.js { render :partial => 'vehicles/form' }
    end
  end

  # POST /vehicles
  # POST /vehicles.json
  def create
    @vehicle = Vehicle.new(vehicle_params)

    # # unless @model.nil? || @property.nil?
    #   @vehicle.property = @property
    #   @vehicle.model = @model
    # end
    respond_to do |format|
      if @vehicle.save# && !@property.nil? && !@model.nil?
        unless @equipment.nil?
          @equipment.each do |e|
            @vehicle.vehicle_equipments << VehicleEquipment.find_by_name(e)
          end
        end
        @informations.each do |k,i|
          t = VehicleInformationType.find(k.to_i)
          unless t.nil? or i.to_s.tr(' ','') == '' or !VehicleInformation.find_by_information(i,t,@vehicle).nil?
            @vehicle.vehicle_informations << VehicleInformation.create(information: i, vehicle_information_type: t, date: Date.current, vehicle: @vehicle)
          end
        end
        # @vehicle.vehicle_informations << VehicleInformation.create(information: @plate, information_type: VehicleInformation.types['Targa'], date: Date.current, vehicle: @vehicle)
        # @vehicle.vehicle_informations << VehicleInformation.create(information: @serial, information_type: VehicleInformation.types['N. di telaio'], date: Date.current, vehicle: @vehicle)
        @informations.each do |k,i|
          t = VehicleInformationType.find(k.to_i)
          unless t.nil? or i.to_s == ''
            @vehicle.vehicle_informations << VehicleInformation.create(information: i, vehicle_information_type: t, date: Date.current, vehicle: @vehicle)
          end
        end
        format.html { redirect_to vehicles_path, notice: 'Vehicle was successfully created.' }
        format.json { render :show, status: :created, location: @vehicle }
      else
        format.html { render :new }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  def new_plate

  end

  def new_chassis

  end

  def update
    respond_to do |format|
      if @vehicle.update(vehicle_params)
        @vehicle.vehicle_equipments.clear
        unless @equipment.nil?
          @equipment.each do |e|
            @vehicle.vehicle_equipments << VehicleEquipment.find_by_name(e)
          end
        end
        # @informations.each do |k,i|
          # t = VehicleInformationType.find(k.to_i)
          # unless t.nil? or i.to_s.tr(' ','') == '' or !VehicleInformation.find_by_information(i,t,@vehicle).nil?
          #   @vehicle.vehicle_informations << VehicleInformation.create(information: i, vehicle_information_type: t, date: Date.current, vehicle: @vehicle)
          # end
        # end
        # unless @vehicle.plate == @informa
        #   @vehicle.vehicle_informations << VehicleInformation.create(information: @plate, information_type: VehicleInformation.types['Targa'])
        # end
        # unless @vehicle.chassis_number == @serial
        #   @vehicle.vehicle_informations << VehicleInformation.create(information: @serial, information_type: VehicleInformation.types['N. di telaio'])
        # end
        # unless @model.nil?
        #   @vehicle.model = @model
        # end
        # unless @property.nil?
        #   @vehicle.property = @property
        # end
        # @vehicle.save
        format.html { redirect_to vehicles_path(search: @search), notice: 'Vehicle was successfully updated.' }
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
    begin
      @vehicle.destroy
    rescue Exception => e
      @error += "Impossibile eliminare mezzo.\n\n#{e.message}"
    end
    @vehicles = Vehicle.filter(@search).sort_by { |v| v.plate } unless @search.nil?
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicles/list_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle
      begin
        @vehicle = Vehicle.find(params.require(:id))
      rescue Exception => e
        @error = "Impossibile trovare mezzo.\n\n#{e.message}\n\n"
      end
    end

    def search_params
      unless params[:search].nil? || params[:search] == '' || params[:search] == ' '
        @search = params.require(:search)
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_params
      # params.require(:vehicle).permit(:dismissed, :registration_date, :serie, :model, :type, :typology, :property, :informations, :notes)
      # @plate = p[:information]['Targa']
      # @serial = params.require(:initial_serial).permit(:info)[:info]


      p = params.require(:vehicle).permit(:dismissed, :registration_date, :serie, :model, :vehicle_type, :vehicle_typology, :property, :informations, :notes, :carwash_code)

      # @informations = params.require(:informations).permit!
      unless params[:equipment].nil?
        @equipment = params.require(:equipment).permit!
      end
      p[:model] = VehicleModel.find(p[:model].to_i)
      p[:vehicle_type] = VehicleType.find(p[:vehicle_type].to_i)
      p[:vehicle_typology] = VehicleTypology.find(p[:vehicle_typology].to_i)
      p[:property] = Company.where(name: p[:property]).first
      p[:dismissed] = p[:dismissed].nil? ? false : true
      p[:carwash_code] = p[:carwash_code].to_i
      p
      # params.require(:vehicle)[:model] = VehicleModel.find(params.require(:vehicle)[:model].to_i)
      # params
    end
end
