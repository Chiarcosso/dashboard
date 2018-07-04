class PresenceController < ApplicationController

  before_action :get_person

  def manage
    begin
      respond_to do |format|
        format.js { render partial: 'presence/manage_js' }
        format.html { render 'presence/index' }
      end
    rescue Exception => e
      @error = e.message
      respond_to do |format|
        format.js { render 'layouts/error' }
      end
    end
  end

  private

  def get_person
    if params['person'].nil?
      @person = Person.order(:surname).first
    else
      @person = Person.find(params.require(:person).to_i)
    end
  end
end
