class VehiclesController < ApplicationController
  include AdminHelper
  before_action :set_vehicle#, only: [:show, :edit, :update, :destroy, :vehicle_information_type_autocomplete, :get_info, :get_workshop_info, :new_information, :create_information]
  before_action :set_vehicle_information, only: [:delete_information]
  before_action :search_params
  autocomplete :vehicle, :plate, full: true

  def vehicle_external_vehicle_autocomplete
    plate = params.require(:search)
    ext = ExternalVehicle.find_by_sql("select 'vehicle' as field, 'ExternalVehicle' as model_name, ev.id as vehicle_id, ev.id as vehicle_id, ev.plate as label from external_vehicles ev where ev.plate like '%#{plate}%'")
    vs = Vehicle.find_by_sql("select 'vehicle' as field, 'Vehicle' as model_name, v.id as vehicle_id, v.id as vehicle, v.model_id, vi.information as label "\
      "from vehicles v inner join vehicle_informations vi on vi.vehicle_id = v.id "\
      "where vi.vehicle_information_type_id = (select id from vehicle_information_types where name = 'Targa') and vi.information like '%#{plate}%' ")
    # render :json => (ext + vs).take(10)
    render :json => vs.take(10)
  end

  def vehicle_information_type_autocomplete
    unless params[:search].nil? or params[:search] == ''
      # array = Language.filter(params.require(:search))
      search = params.require(:search).tr(' ','%')
      # array = VehicleInformationType.find_by_sql("select 'vehicle_information_type' as field, 'Vehicle' as model, c.id as 'vehicle_information_type_id', c.name as label from vehicle_information_types c where c.name like '%#{search}%' and c.vehicle_information_type limit 10")
      array = @vehicle.possible_information_types.map { |it| {field: 'vehicle_information_type', model: 'Vehicle', vehicle_information_type_id: it.id, label: it.name}}
      render :json => array
    end
  end

  def info_for_workshop
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'workshop/worksheet_side_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def assignation

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

  def get_checks_info
    respond_to do |format|
      format.js { render :partial => 'vehicles/infobox_checks' }
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
    @vehicle.carwash_code = Vehicle.carwash_codes['N/D']
    @vehicle_types = VehicleType.all
    @vehicle_typologies = VehicleTypology.all
    @informations = get_vehicle_informations
    @gear = Gear.order(:name)
    @equipment = VehicleEquipment.order(:name)
    respond_to do |format|
      format.html { render 'vehicles/new' }
    end
  end

  # POST /vehicles/edit
  def edit
    @vehicle_types = VehicleType.all
    @vehicle_typologies = VehicleTypology.all
    # @information_types = VehicleInformationType.all

    # @informations = info + @vehicle.possible_informations.map { |i| VehicleInformation.new(vehicle: @vehicle, information_type: i, date: Date.current) unless info.map { |vi| vi.information_type }.include?(i)  }
    @gear = Gear.order(:name)
    @equipment = VehicleEquipment.order(:name)
    @informations = get_vehicle_informations
    respond_to do |format|
      format.html { render 'vehicles/edit' }
    end
  end

  def change_type
    @vehicle = Vehicle.new if @vehicle.nil?
    @vehicle.vehicle_type = VehicleType.find(params.require(:vehicle_type_id).to_i)
    @vehicle.vehicle_category = VehicleCategory.find(params.require(:vehicle_category_id).to_i)
    @vehicle.vehicle_typology = VehicleTypology.find(params.require(:vehicle_typology_id).to_i)
    @vehicle.model = VehicleModel.find(params.require(:vehicle_model_id).to_i)
    # @vehicle.carwash_code = params.require(:carwash_code).to_i
    @vehicle.carwash_code = @vehicle.get_carwash_code if @vehicle.id.nil?
    @vehicle.vehicle_equipments.clear
    unless params[:vehicle_equipment].nil?
      params.require(:vehicle_equipments).each do |e|
        @vehicle.vehicle_equipments << VehicleEquipment.find(e.to_i)
      end
    end
    # @vehicle_types = @vehicle.get_types
    # @vehicle_typologies = @vehicle.vehicle_type.vehicle_typologies
    # @vehicle_models = VehicleModel.manufacturer_model_order
    # @informations = get_vehicle_informations
    respond_to do |format|
      format.js { render partial: 'vehicles/change_types_js' }
    end
  end

  def get_carwash_code
    self.vehicle_type.carwash_code
  end

  def new_information
    @information_type = VehicleInformationType.find(params.require(:information_type))
    @vehicle_information = VehicleInformation.new(vehicle_information_type: @information_type, vehicle: @vehicle)
    respond_to do |format|
      format.js { render partial: 'vehicles/information_form'}
    end
  end

  def create_information
    begin
      @vehicle_information = VehicleInformation.create(vehicle_information_params)
      @informations = get_vehicle_informations
    rescue Exception => e
      @error = "#{e.message}"
    end

    respond_to do |format|
      if @error.nil?
        if @vehicle_information.vehicle_information_type == VehicleInformationType.plate or @vehicle_information.vehicle_information_type == VehicleInformationType.chassis
          format.js { render partial: 'vehicles/all_vehicle_informations_js'}
        else
          format.js { render partial: 'vehicles/vehicle_informations_js'}
        end
      else
        format.js { render partial: 'layouts/error'}
      end
    end
  end

  def delete_information
    begin
      @vehicle_information.destroy
      @informations = get_vehicle_informations
    rescue Exception => e
      @error = "Impossibile eliminare l'informazione.\n\n#{e.message}"
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicles/vehicle_informations_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def create
    begin
      @error = "Targa già esistente." unless Vehicle.find_by_plate(params[:vehicle_plate][:information]).nil?
      @vehicle = Vehicle.new(vehicle_params) if @error.nil?
    rescue Exception => e
      @error = "#{e.message}"
    end
    begin
      params.require(:vehicle_plate).permit('information','date')
      if params[:vehicle_plate][:information] == '' or params[:vehicle_plate][:date] == ''
        @error = "Inserire la targa con data."
      end
    rescue Exception => e
      @error = "Inserire la targa con data. #{e.message}"
    end
    begin
      params.require(:vehicle_chassis).permit('information','date')
      if params[:vehicle_chassis][:information] == '' or params[:vehicle_chassis][:date] == ''
        @error = "Inserire il numero di telaio con data."
      end
    rescue Exception => e
      @error = "Inserire il numero di telaio con data. #{e.message}"
    end
    if @error.nil?
      begin
        @vehicle.save
      rescue Exception => e
        @error = "#{e.message}"
      end
    end
    if @error.nil?
      begin
        if @vehicle.last_information(VehicleInformationType.plate).nil?
          params[:vehicle_plate][:vehicle_id] = @vehicle.id
          params[:vehicle_plate][:vehicle_information_type_id] = VehicleInformationType.plate.id
          params[:vehicle_plate][:information] = params[:vehicle_plate][:information].upcase
          plate = params.require(:vehicle_plate).permit(:date,:vehicle_information_type_id,:vehicle_id, :information)
          params[:vehicle_chassis][:vehicle_id] = @vehicle.id
          params[:vehicle_chassis][:vehicle_information_type_id] = VehicleInformationType.chassis.id
          params[:vehicle_chassis][:information] = params[:vehicle_chassis][:information].upcase
          chassis = params.require(:vehicle_chassis).permit(:date,:vehicle_information_type_id,:vehicle_id, :information)
          VehicleInformation.create(plate)
          VehicleInformation.create(chassis)
        end

        params[:informations].each do |info|
          info[:vehicle_id] = @vehicle.id
          info[:date] = @vehicle.registration_date
          info = info.permit(:vehicle_id,:vehicle_information_type_id,:date,:information)
          VehicleInformation.create(info) unless info[:information] == ''
        end

        unless params[:equipment].nil?
          params[:equipment].permit!.each do |equip|
            @vehicle.vehicle_equipments << VehicleEquipment.find_by_name(equip)
          end
        end
      rescue Exception => e
        @error = "#{e.message}"
      end
    end
    respond_to do |format|
      if @error.nil?
        # format.js { render :partial => 'vehicles/list_js' }
        @vehicles = Vehicle.filter(@search).sort_by { |v| v.plate } unless @search.nil?
        format.js { render 'vehicles/index_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end

  end

  def new_plate

  end

  def new_chassis

  end

  def update
    begin
      @vehicle.update(vehicle_params)
      @vehicle.vehicle_equipments.clear
      unless @equipment.nil?
        @equipment.each do |e|
          @vehicle.vehicle_equipments << VehicleEquipment.find_by_name(e)
        end
      end
    rescue Exception => e
      @error = "#{e.message}"
    end

    respond_to do |format|
      if @error.nil?
        # format.js { render :partial => 'vehicles/list_js' }
        @vehicles = Vehicle.filter(@search).sort_by { |v| v.plate } unless @search.nil?
        format.js { render 'vehicles/index_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def massive_update
    # byebug
    begin
      @view = 'altri_mezzi'
    rescue Exception => e
      @error = e.message
    end
    query_vehicles
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'admin/import_vehicles_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  def destroy
    if @vehicle.worksheets.empty?
      begin
        @vehicle.destroy
      rescue Exception => e
        @error = "Impossibile eliminare mezzo.\n\n#{e.message}"
      end
    else
      @error = "Esistono ODL per questo mezzo."
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

  def massive_delete
    begin
      params.require(:vehicles_list).each do |v|
        Vehicle.find(v.to_i).destroy
      end
    rescue Exception => e
      @error = e.message
    end
    query_vehicles
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'admin/import_vehicles_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def get_vehicle_informations
      @informations = @vehicle.vehicle_informations
      info = (@vehicle.vehicle_type.vehicle_information_types + @vehicle.vehicle_type.vehicle_information_types).uniq
      missing_informations = Array.new
      info.each { |i| missing_informations << VehicleInformation.new(vehicle_information_type: i, vehicle: @vehicle) unless @informations.map { |vi| vi.vehicle_information_type }.include? i}
      # missing_informations.reject! { |i| @informations.map { |vi| vi.vehicle_information_type }.include? i }
      @informations += missing_informations
      @informations -= [@vehicle.last_information(VehicleInformationType.plate),@vehicle.last_information(VehicleInformationType.chassis)]
      # byebug
      @informations.sort_by! { |i| i.vehicle_information_type.name }
    end

    def set_vehicle
      unless params[:id].nil?
        begin
          @vehicle = Vehicle.find(params.require(:id))

        rescue Exception, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound  => e
          @error = "Impossibile trovare mezzo.\n\n#{e.message}\n\n"
        end
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

      begin
        p = params.require(:vehicle).permit(:dismissed, :registration_date, :serie, :model, :registration_model, :vehicle_type_id, :vehicle_typology_id, :property, :notes, :carwash_code, :search, :equipment, :mileage, :property_id)

        # @informations = params.require(:informations).permit!
        unless params[:equipment].nil?
          @equipment = params.require(:equipment).permit!
        end
        p[:model] = VehicleModel.find(p[:model].to_i)
        # p[:vehicle_type] = VehicleType.find(p[:vehicle_type].to_i)
        # p[:vehicle_typology] = VehicleTypology.find(p[:vehicle_typology].to_i)
        p[:property] = Company.where(name: p[:property]).first
        @error = "Inserire la proprietà." if p[:property].nil?
        p[:dismissed] = p[:dismissed].nil? ? false : true
        p[:carwash_code] = p[:carwash_code].to_i
      rescue Exception => e
        @error = e.message
      end
      p
      # params.require(:vehicle)[:model] = VehicleModel.find(params.require(:vehicle)[:model].to_i)
      # params
    end

    def set_vehicle_information
      begin
        @vehicle_information = VehicleInformation.find(params.require(:vehicle_information).permit(:id)[:id])
      rescue Exception, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
        @error = "Impossibile trovare l'informazione (id: #{params[:id]}).\n\n#{e.message}"
      end
    end

    def vehicle_information_params
      p = params.require(:vehicle_information).permit(:vehicle_id, :vehicle_information_type_id, :information, :date)
      if p[:vehicle_information_type_id].to_i == VehicleInformationType.plate.id or p[:vehicle_information_type_id].to_i == VehicleInformationType.chassis.id
        p[:information] = p[:information].upcase
      end
      p
    end
end
