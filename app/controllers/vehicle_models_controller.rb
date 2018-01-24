class VehicleModelsController < ApplicationController
  before_action :set_vehicle_model, only: [:show, :edit, :update, :destroy]
  before_action :search_params
  # GET /vehicle_models
  # GET /vehicle_models.json
  def index
    @vehicle_models = VehicleModel.filter(@search).manufacturer_model_order unless @search.nil?
    respond_to do |format|
      format.js { render :partial => 'vehicle_models/list_js' }
      format.html { render 'vehicle_models/index' }
    end
  end

  def get_info
    @vehicle_model = VehicleModel.find(params.require(:id))
    respond_to do |format|
      format.js { render :partial => 'vehicle_models/infobox' }
    end
  end

  def new
    @vehicle_model = VehicleModel.new
    respond_to do |format|
      format.js { render :partial => 'vehicle_models/form_new' }
    end
  end

  # GET /vehicle_models/1/edit
  def edit
    respond_to do |format|
      format.js { render :partial => 'vehicle_models/form' }
    end
  end

  def create
    begin
      @vehicle_model = VehicleModel.create(vehicle_model_params)
      unless params[:vehicle_model_types].nil?
        params.require(:vehicle_model_types).each do |vtt|
          @vehicle_model.vehicle_types << VehicleType.find(vtt.to_i)
        end
      end
      unless params[:vehicle_model_typologies].nil?
        params.require(:vehicle_model_typologies).each do |vtt|
          @vehicle_model.vehicle_typologies << VehicleTypology.find(vtt.to_i)
        end
      end
      unless params[:vehicle_model_equipments].nil?
        params.require(:vehicle_model_equipments).each do |ve|
          @vehicle_model.vehicle_equipments << VehicleEquipment.find(ve.to_i)
        end
      end
      unless params[:vehicle_model_information_types].nil?
        params.require(:vehicle_model_information_types).each do |vi|
          @vehicle_model.vehicle_information_types << VehicleInformationType.find(vi.to_i)
        end
      end
    rescue Exception => e
      @error += "Impossibile creare modello: #{vehicle_model_params.inspect}.\n\n#{e.message}"
    end
    @vehicle_models = VehicleModel.filter(@search).manufacturer_model_order unless @search.nil?
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicle_models/list_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  # PATCH/PUT /vehicle_models/1
  # PATCH/PUT /vehicle_models/1.json
  def update
    # p = vehicle_model_params
    begin
      @vehicle_model.update(vehicle_model_params)
      @vehicle_model.vehicle_types.clear
      unless params[:vehicle_model_types].nil?
        params.require(:vehicle_model_types).each do |vtt|
          @vehicle_model.vehicle_types << VehicleType.find(vtt.to_i)
        end
      end
      @vehicle_model.vehicle_typologies.clear
      unless params[:vehicle_model_typologies].nil?
        params.require(:vehicle_model_typologies).each do |vtt|
          @vehicle_model.vehicle_typologies << VehicleTypology.find(vtt.to_i)
        end
      end
      @vehicle_model.vehicle_equipments.clear
      unless params[:vehicle_model_equipments].nil?
        params.require(:vehicle_model_equipments).each do |ve|
          @vehicle_model.vehicle_equipments << VehicleEquipment.find(ve.to_i)
        end
      end
      @vehicle_model.vehicle_information_types.clear
      unless params[:vehicle_model_information_types].nil?
        params.require(:vehicle_model_information_types).each do |vi|
          @vehicle_model.vehicle_information_types << VehicleInformationType.find(vi.to_i)
        end
      end
    rescue Exception => e
      @error = "#{e.message}"
    end
    # respond_to do |format|
    #   format.html { redirect_to  'vehicle_types/index' }
    # end
    # redirect_to '/vehicle_types'
    @vehicle_models = VehicleModel.filter(@search).manufacturer_model_order unless @search.nil?
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicle_models/list_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  # DELETE /vehicle_models/1
  # DELETE /vehicle_models/1.json
  def destroy
    begin
      @vehicle_model.destroy
    rescue Exception => e
      @error = "Impossibile eliminare modello: #{@vehicle_model.complete_name}.\n\n#{e.message}"
    end
    @vehicle_models = VehicleModel.filter(@search).manufacturer_model_order unless @search.nil?
    respond_to do |format|
      if @error.nil?
        format.js { render :partial => 'vehicle_models/list_js' }
      else
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_model
      @vehicle_model = VehicleModel.find(params[:id])
    end

    def search_params
      unless params[:search].nil? || params[:search] == '' || params[:search] == ' '
        @search = params.require(:search)
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_model_params

      begin
        p = params.require(:vehicle_model).permit(:name, :description, :manufacturer,:manufacturer_id)
        @manufacturer = Company.find(params.require('VehicleModel').permit(:manufacturer_id)[:manufacturer_id].to_i)
        @manufacturer = Company.find(p[:manufacturer_id].to_i) if @manufacturer.nil?
        if @manufacturer.nil?
          # @manufacturer = Company.create(name: params.require(:model).permit(:manufacturer)[:manufacturer])
          @error = "Produttore non esistente: #{p[:manufacturer]} (#{p[:manufacturer_id]}).\n\n"
        elsif @manufacturer.name != p[:manufacturer]
          @error = "Produttore non esistente: #{p[:manufacturer]} (Prod. impostato #{@manufacturer.name}).\n\n"
        elsif !p[:name].match(/^[\s]*$/).nil? or p[:name].nil?
          @error = "Modello non valido: '#{p[:name]}'\n\n"
        else
          p[:manufacturer] = @manufacturer
        end
      rescue Exception => e
        @error = "#{e.message}\n\n"
      end
      # params.require(:vehicle_model).permit(:name, :description)
      p
      # p[:vehicle_type] = VehicleType.find(p[:vehicle_type].to_i)
      # p
    end
end
