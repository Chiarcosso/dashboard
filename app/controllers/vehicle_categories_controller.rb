class VehicleCategoriesController < ApplicationController
  before_action :set_vehicle_category, only: [:show, :edit, :update, :destroy]

  # GET /vehicle_categories
  # GET /vehicle_categories.json
  def index
    @vehicle_categories = VehicleCategory.all
  end

  # GET /vehicle_categories/1
  # GET /vehicle_categories/1.json
  def show
  end

  # GET /vehicle_categories/new
  def new
    @vehicle_category = VehicleCategory.new
  end

  # GET /vehicle_categories/1/edit
  def edit
    respond_to do |format|
      format.js { render :partial => 'vehicle_categories/form' }
    end
  end

  # POST /vehicle_categories
  # POST /vehicle_categories.json
  def create
    # p = vehicle_category_params
    begin
      @vehicle_category = VehicleCategory.create(vehicle_category_params) if @vehicle_category.nil?
    rescue Exception => e
      @error = "Impossibile creare categoria.\n\n#{e.message}"
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicle_categories/form'}
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  # PATCH/PUT /vehicle_categories/1
  # PATCH/PUT /vehicle_categories/1.json
  def update
    begin
      @vehicle_category.update(vehicle_category_params)
      @vehicle_category.vehicle_types.clear
      unless params[:vehicle_category_types].nil?
        params.require(:vehicle_category_types).each do |vt|
          @vehicle_category.vehicle_types << VehicleType.find(vt.to_i)
        end
      end
      @vehicle_category.vehicle_typologies.clear
      unless params[:vehicle_category_typologies].nil?
        params.require(:vehicle_category_typologies).each do |vt|
          @vehicle_category.vehicle_typologies << VehicleTypology.find(vt.to_i)
        end
      end
      @vehicle_category.vehicle_models.clear
      unless params[:vehicle_category_models].nil?
        params.require(:vehicle_category_models).each do |ve|
          @vehicle_category.vehicle_models << VehicleModel.find(ve.to_i)
        end
      end
    rescue Exception => e
      @error = "Impossibile aggiornare categoria.\n\n#{e.message}"
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicle_categories/list_js'}
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  # DELETE /vehicle_categories/1
  # DELETE /vehicle_categories/1.json
  def destroy
    begin
      @vehicle_category.destroy
    rescue Exception => e
      @error = "Impossibile eliminare categoria mezzo: #{@vehicle_category.name}.\n\n#{e.message}"
    end
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicle_categories/list_js'}
      else
        format.js { render :partial => 'layouts/error' }
      end
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_category
      @vehicle_category = VehicleCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_category_params
      p = params.require(:vehicle_category).permit(:name,:description)
      p[:name].capitalize!
      # @vehicle_category = VehicleCategory.find_by_name(p[:name])
      p
    end
end
