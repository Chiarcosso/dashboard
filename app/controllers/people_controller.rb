class PeopleController < ApplicationController
  before_action :set_person, only: [:show, :edit, :update, :destroy, :add_role]
  before_action :search_params

  autocomplete :company, :name, full: true

  # GET /people
  # GET /people.json
  def index
    if @search.nil? || @search == ""
      @filteredPeople = Array.new
    else
      @filteredPeople = Person.filter(@search)
    end
    render 'people/index'
  end

  # GET /people/1
  # GET /people/1.json
  def show
  end

  # GET /people/new
  def new
    @person = Person.new
  end

  # GET /people/1/edit
  def edit
  end

  # POST /people
  # POST /people.json
  def create
    @person = Person.where(:name => person_params[:name]).where(:surname => person_params[:surname]).first
    if @person.nil?
      @person = Person.create(person_params)
    # else
    #   @person.update(params.require(:person).permit(:name,:surname,:notes,:mdc_user))
    #   index
    end

    redirect_to edit_person_path(@person.id)
    # respond_to do |format|
    #   if @person.save
    #     # Person.where(mdc_user: @person.mdc_user).where("id != #{@person.id}").update(mdc_user: nil)
    #     # mdc = MdcWebservice.new
    #     # mdc.begin_transaction
    #     # Person.mdc.each do |p|
    #     #   mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: p.mdc_user.upcase, key: p.mdc_user, order: 1, tabname: 'USERS', values: [p.mdc_user.upcase,p.mdc_user,p.name,p.surname,p.id]}))
    #     # end
    #     # mdc.commit_transaction
    #     # mdc.end_transaction
    #     # mdc.close_session
    #     # relation_params
    #     # CompanyPerson.create(company: @company, person: @person, company_relation: @relation)
    #     # format.html { redirect_to edit_person_path(@person.id), notice: 'Persona creata con successo.' }
    #     # format.json { render :show, status: :created, location: @person }
    #     index
    #   else
    #     format.html { render :new }
    #     format.json { render json: @person.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /people/1
  # PATCH/PUT /people/1.json
  def update
    @person.update(person_params)
    index
    # respond_to do |format|
    #   if @person.update(person_params)
    #     # Person.where(mdc_user: @person.mdc_user).where("id != #{@person.id}").update(mdc_user: nil)
    #     # mdc = MdcWebservice.new
    #     # mdc.begin_transaction
    #     # Person.mdc.each do |p|
    #     #   mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "|#{ p.mdc_user.upcase}|", key: p.mdc_user, order: 1, tabname: 'USERS', values: [p.mdc_user.upcase,p.mdc_user,p.name,p.surname,p.id]}))
    #     # end
    #     # mdc.commit_transaction
    #     # mdc.end_transaction
    #     # mdc.close_session
    #     # relation_params
    #     # CompanyPerson.create(company: @company, person: @person, company_relation: @relation)
    #     # format.html { redirect_to people_path, notice: 'Aggiornato con successo.' }
    #     # format.json { render :show, status: :ok, location: @person }
    #     index
    #   else
    #     format.html { render :edit }
    #     format.json { render json: @person.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  def add_role
    company = Company.find(params[:relation][:company].to_i)
    role = CompanyRelation.find(params[:relation][:relation].to_i)
    CompanyPerson.create(person: @person, company: company, company_relation: role)
    # unless params[:id].nil? || params[:id] == ''
    #   cp = CompanyPerson.find(params.require(:id))
    #   p = cp.person_id
    #   cp.destroy
    # end
    render :js, :partial => 'people/relations_list_js'
  end

  def delete_role
    unless params[:id].nil? || params[:id] == ''
      cp = CompanyPerson.find(params.require(:id))
      @person = cp.person
      cp.destroy
      render :js, :partial => 'people/relations_list_js'
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person.destroy
    index
    # respond_to do |format|
    #   format.html { redirect_to people_path, notice: 'Person was successfully destroyed.' }
    #   format.json { head :no_content }
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_person
      @person = Person.find(params[:id])
    end

    def search_params
      unless params[:search].nil? || params[:search] == ''
        @search = params.require(:search)
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def person_params
      p = params.require(:person).permit(:name, :surname, :notes, :search)
      p[:name] = p[:name].strip.titleize
      p[:surname] = p[:surname].strip.titleize
      p
    end

    def relation_params
      # params[:relation][:person] = @person.id
      rel = params.require(:relation).permit(:company, :relation, :person, :search)
      @company = Company.find(rel[:company])
      @relation = CompanyRelation.find(rel[:relation])
    end
end
