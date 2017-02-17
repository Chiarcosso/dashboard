class CompanyRelationsController < ApplicationController
  before_action :set_company_relation, only: [:show, :edit, :update, :destroy]

  # GET /company_relations
  # GET /company_relations.json
  def index
    @company_relations = CompanyRelation.all
  end

  # GET /company_relations/1
  # GET /company_relations/1.json
  def show
  end

  # GET /company_relations/new
  def new
    @company_relation = CompanyRelation.new
  end

  # GET /company_relations/1/edit
  def edit
  end

  # POST /company_relations
  # POST /company_relations.json
  def create
    @company_relation = CompanyRelation.new(company_relation_params)

    respond_to do |format|
      if @company_relation.save
        format.html { redirect_to @company_relation, notice: 'Company relation was successfully created.' }
        format.json { render :show, status: :created, location: @company_relation }
      else
        format.html { render :new }
        format.json { render json: @company_relation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /company_relations/1
  # PATCH/PUT /company_relations/1.json
  def update
    respond_to do |format|
      if @company_relation.update(company_relation_params)
        format.html { redirect_to @company_relation, notice: 'Company relation was successfully updated.' }
        format.json { render :show, status: :ok, location: @company_relation }
      else
        format.html { render :edit }
        format.json { render json: @company_relation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /company_relations/1
  # DELETE /company_relations/1.json
  def destroy
    @company_relation.destroy
    respond_to do |format|
      format.html { redirect_to company_relations_url, notice: 'Company relation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_relation
      @company_relation = CompanyRelation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def company_relation_params
      params.require(:company_relation).permit(:name)
    end
end
