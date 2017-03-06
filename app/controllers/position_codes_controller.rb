class PositionCodesController < ApplicationController
  before_action :set_position_code, only: [:show, :edit, :update, :destroy, :print]
  # after_action :reset_position_code, only: [:index, :create, :show, :edit, :update, :destroy]

  # GET /position_codes
  # GET /position_codes.json
  def index
    @positionCodes = PositionCode.all
    @position_code = PositionCode.new
    render :partial => 'position_codes/index'
  end

  # GET /position_codes/1
  # GET /position_codes/1.json
  def show
  end

  # GET /position_codes/new
  def new
    @position_code = PositionCode.new
  end

  # GET /position_codes/1/edit
  def edit
  end

  def print
    @position_code.printLabel
    @positionCodes = PositionCode.all
    @position_code = PositionCode.new
  end
  # POST /position_codes
  # POST /position_codes.json
  def create
    @position_code = PositionCode.new
    PositionCode.create(position_code_params)
    @positionCodes = PositionCode.all
    respond_to do |format|
      format.js { render :js, :partial => 'position_codes/index' }
    end
  end

  # PATCH/PUT /position_codes/1
  # PATCH/PUT /position_codes/1.json
  def update
    @position_code = PositionCode.new
    respond_to do |format|
      if @position_code.update(position_code_params)
        @positionCodes = PositionCode.all
        format.html { redirect_to @position_code, notice: 'Position code was successfully updated.' }
        format.json { render :show, status: :ok, location: @position_code }
      else
        format.html { render :edit }
        format.json { render json: @position_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /position_codes/1
  # DELETE /position_codes/1.json
  def destroy
    @position_code.destroy
    @position_code = PositionCode.new
    @positionCodes = PositionCode.all
    respond_to do |format|
      format.js { render :js, :partial => 'position_codes/index' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_position_code
      @position_code = PositionCode.find(params[:id])
    end

    # def reset_position_code
    #   @position_code = PositionCode.new
    # end
    # Never trust parameters from the scary internet, only allow the white list through.
    def position_code_params
      params[:position_code][:row] = params[:position_code][:row].to_i
      params[:position_code][:section] = params[:position_code][:section].to_i
      params.require(:position_code).permit(:floor, :row, :level, :sector, :section, :description)
    end
end
