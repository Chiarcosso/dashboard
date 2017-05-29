class EquipmentGroupsController < ApplicationController
  before_action :set_equipment_group, only: [:show, :edit, :update, :destroy]

  # GET /equipment_groups
  # GET /equipment_groups.json
  def index
    @equipment_groups = EquipmentGroup.all
  end

  # GET /equipment_groups/1
  # GET /equipment_groups/1.json
  def show
  end

  # GET /equipment_groups/new
  def new
    @equipment_group = EquipmentGroup.new
  end

  # GET /equipment_groups/1/edit
  def edit
  end

  # POST /equipment_groups
  # POST /equipment_groups.json
  def create
    @equipment_group = EquipmentGroup.new(equipment_group_params)

    respond_to do |format|
      if @equipment_group.save
        format.html { redirect_to @equipment_group, notice: 'Equipment group was successfully created.' }
        format.json { render :show, status: :created, location: @equipment_group }
      else
        format.html { render :new }
        format.json { render json: @equipment_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /equipment_groups/1
  # PATCH/PUT /equipment_groups/1.json
  def update
    respond_to do |format|
      if @equipment_group.update(equipment_group_params)
        format.html { redirect_to @equipment_group, notice: 'Equipment group was successfully updated.' }
        format.json { render :show, status: :ok, location: @equipment_group }
      else
        format.html { render :edit }
        format.json { render json: @equipment_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /equipment_groups/1
  # DELETE /equipment_groups/1.json
  def destroy
    @equipment_group.destroy
    respond_to do |format|
      format.html { redirect_to equipment_groups_url, notice: 'Equipment group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_equipment_group
      @equipment_group = EquipmentGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def equipment_group_params
      params.require(:equipment_group).permit(:name)
    end
end
