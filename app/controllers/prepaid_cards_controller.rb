class PrepaidCardsController < ApplicationController

  before_action :search
  before_action :get_card, only: [:edit]

  def index

    respond_to do |format|
      format.js {
        @prepaid_cards = PrepaidCard.active(@active).filter(@search).person_alpha_order
        render partial: 'prepaid_cards/index_js'
      }
      format.html {
        @active = true
        @prepaid_cards = PrepaidCard.active(@active).filter(@search).person_alpha_order
        render 'prepaid_cards/index'
      }
    end
  end

  def new
    begin
      p = get_params
      unless PrepaidCard.find_by(:serial => p[:serial]).nil?
        raise "La carta nr. #{p[:serial]} esiste già."
      end
      PrepaidCard.create(p)
      @prepaid_cards = PrepaidCard.active(@active).filter(@search)
      respond_to do |format|
        format.js { render partial: 'prepaid_cards/index_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render partial: 'layouts/error' }
      end
    end
  end

  def edit
    begin
      p = get_params
      pc = PrepaidCard.find_by(:serial => p[:serial])
      unless pc.nil? || pc == @card
        raise "La carta nr. #{p[:serial]} esiste già."
      end
      @card.update(p)
      @prepaid_cards = PrepaidCard.active(@active).filter(@search)
      respond_to do |format|
        format.js { render partial: 'prepaid_cards/index_js' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render :partial => 'layouts/error' }
      end
    end
  end

  private

  def get_params
    p = params.require(:prepaid_card).permit(:serial,:pin,:dismissed,:expiring_date,:person)
    if p[:pin].to_s == ''
      raise 'Manca il PIN.'
    end
    person = Person.find(p[:person].to_i) unless p[:person].to_i == 0
    p[:person] = person
    p[:dismissed] = p[:dismissed] == 'true' ? true : false
    p
  end

  def search
    @search = params.require(:search) unless params[:search].to_s == ''
    unless params[:active].to_s == ''
      case params.require(:active)
      when 'true' then
        @active = true
      when 'false' then
        @active = false
      end
    end
  end

  def get_card
    @card = PrepaidCard.find(params.require(:id).to_i)
  end
end
