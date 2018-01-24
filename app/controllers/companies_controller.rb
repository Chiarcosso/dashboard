class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy, :add_address, :del_address]
  before_action :search_params
  before_action :set_address, only: [:update_address]
  before_action :search_params, only: [:index,:destroy]

  autocomplete :company, :name, full: true
  autocomplete :geo_city, :name, full: true

  def vehicle_manufacturer_multi_autocomplete
    unless params[:search].nil? or params[:search] == ''
      # array = Language.filter(params.require(:search))
      search = params.require(:search).tr(' ','%')
      array = Company.find_by_sql("select 'manufacturer' as field, 'Company' as model, c.id as 'manufacturer_id[]id', c.name as label from companies c where c.name like '%#{search}%' and c.vehicle_manufacturer limit 10")
      render :json => array #GeoCity.find_by_sql("select geo_cities.id as id, geo_cities.name as name, geo_province.name as province, geo_province.code as province_code, geo_state.name as state, geo_state.code as state_code from geo_cities inner join geo_provinces on geo_cities.geo_province_id = geo_province.id inner join geo_states on geo_province.geo_state_id = geo_state.id")
    end
  end

  def vehicle_manufacturer_autocomplete
    unless params[:search].nil? or params[:search] == ''
      # array = Language.filter(params.require(:search))
      search = params.require(:search).tr(' ','%')
      array = Company.find_by_sql("select 'manufacturer' as field, 'Company' as model, c.id as 'manufacturer_id', c.name as label from companies c where c.name like '%#{search}%' and c.vehicle_manufacturer limit 10")
      render :json => array #GeoCity.find_by_sql("select geo_cities.id as id, geo_cities.name as name, geo_province.name as province, geo_province.code as province_code, geo_state.name as state, geo_state.code as state_code from geo_cities inner join geo_provinces on geo_cities.geo_province_id = geo_province.id inner join geo_states on geo_province.geo_state_id = geo_state.id")
    end
  end

  def vehicle_property_autocomplete
    unless params[:search].nil? or params[:search] == ''
      # array = Language.filter(params.require(:search))
      search = params.require(:search).tr(' ','%')
      array = Company.find_by_sql("select 'property' as field, 'Company' as model, c.id as 'property_id', c.name as label from companies c where c.name like '%#{search}%' and c.transporter limit 10")
      render :json => array #GeoCity.find_by_sql("select geo_cities.id as id, geo_cities.name as name, geo_province.name as province, geo_province.code as province_code, geo_state.name as state, geo_state.code as state_code from geo_cities inner join geo_provinces on geo_cities.geo_province_id = geo_province.id inner join geo_states on geo_province.geo_state_id = geo_state.id")
    end
  end

  def index

    @companies = Company.filter(@search) unless @search.nil?#.paginate(:page => params[:page], :per_page => 30)

    respond_to do |format|
      format.html { render 'companies/index', notice: @notice}
    end
  end

  def add_address
    ca = CompanyAddress.create(address_params)
    @company.update(main_address: ca) if @hq
    respond_to do |format|
      format.js { render 'companies/address_added', notice: @notice}
    end
  end

  def del_address
    address = CompanyAddress.find(params.require(:address_id))
    @company.update(main_address: @company.company_addresses.first)
    address.destroy
    respond_to do |format|
      format.js { render 'companies/address_added', notice: @notice}
    end
  end
  # GET /companies/1
  # GET /companies/1.json
  def show
  end

  def edit_address_popup
    @address = CompanyAddress.find(params.require(:address_id))
    render :js, :partial => 'companies/edit_address_block'
  end

  def update_address
    @address.update(address_params)
    @company.update(main_address: @address) if @hq
    @address.workshop_brands.each { |wb| wb.destroy}
    @manufacturers.each do |m|
      @address.workshop_brands << WorkshopBrand.create(workshop: @address, brand: m)
    end
    respond_to do |format|
      format.js { render 'companies/address_added', notice: @notice}
    end
  end
  # GET /companies/new
  def new
    @company = Company.new
  end

  # GET /companies/1/edit
  def edit
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(company_params)

    respond_to do |format|
      if @company.save
        format.html { render 'companies/index', notice: "Ditta #{@company.name} creata." }
        format.json { render :show, status: :created, location: @company }
      else
        format.html { render 'companies/new', notice: "Errori nella registrazione." }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    respond_to do |format|
      if @company.update(company_params)
        format.html { render 'companies/index', notice: "Ditta #{@company.name} aggiornata." }
        format.json { render :show, status: :ok, location: @company }
      else
        format.html { render 'companies/new', notice: "Errori nella registrazione." }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company.destroy
    index
    # respond_to do |format|
    #   format.html { redirect_to companies_url, notice: 'Company was successfully destroyed.' }
    #   format.json { head :no_content }
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def search_params
      unless params[:search].nil? || params[:search] == '' || params[:search] == ' '
        @search = params.require(:search)
      end
    end

    def set_company
      @company = Company.find(params[:id])
    end

    def set_address
      @address = CompanyAddress.find(params[:id])
      @company = @address.company
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def company_params
      params.require(:company).permit(:name, :vat_number, :ssn, :client, :supplier, :workshop, :transporter, :vehicle_manufacturer, :item_manufacturer, :notes, :formation_institute, :institution, :search)
    end

    def address_params
      @hq = true if params[:CompanyAddress][:headquarter] == '1'
      p = params.require('CompanyAddress').permit(:street, :number, :internal, :geo_city_id, :zip, :geo_locality, :workshop, :loading_facility, :unloading_facility, :closed, :notes, :location_qualification, :manufacturer_id => [:id])
      @manufacturers = Array.new
      unless p[:manufacturer_id].nil?
        p[:manufacturer_id].each do |m|
          man = Company.find(m[:id].to_i)
          @manufacturers << man unless man.nil?
        end
        p.delete(:manufacturer_id)
      end
      p[:company] = @company
      p[:geo_city]  = GeoCity.find(p[:geo_city_id].to_i) unless p[:geo_city_id].nil?
      if p[:geo_locality].nil?
        p[:geo_locality] = nil
      else
        p[:geo_locality] = GeoLocality.find(p[:geo_locality].to_i) unless p[:geo_locality].nil?
      end
      p
    end
end
