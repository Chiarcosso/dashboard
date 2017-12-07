class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy, :add_address, :del_address]
  before_action :search_params, only: [:index,:destroy]

  autocomplete :company, :name, full: true
  autocomplete :geo_city, :name, full: true
  # GET /vehicles
  # GET /vehicles.json
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
    byebug
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
    def set_company
      @company = Company.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def company_params
      params.require(:company).permit(:name, :vat_number, :ssn, :client, :supplier, :workshop, :transporter, :manufacturer, :notes)
    end

    def search_params
      unless params[:search].nil? || params[:search] == ''
        @search = params.require(:search)
      end
    end

    def address_params
      @hq = true if params[:CompanyAddress][:headquarter] = '1'
      p = params.require('CompanyAddress').permit(:street, :number, :internal, :geo_city, :zip, :geo_locality, :workshop, :loading_facility, :unloading_facility, :closed, :notes, :location_qualification)

      p[:company] = @company
      p[:geo_city]  = GeoCity.find(p[:geo_city].to_i) unless p[:geo_city].nil?
      p[:geo_locality]  = GeoLocality.find(p[:geo_locality].to_i) unless p[:geo_locality].nil?
      p
    end
end
