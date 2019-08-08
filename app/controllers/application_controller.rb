class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  # include AppHelper

  before_action :authenticate_user!
  before_action :user_active?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :get_scroll
  helper_method :resource_name, :resource, :devise_mapping

  # # GET /autocomplete/:model/:search.json
  # def autocomplete
  #   if params[:search] && params[:model]
  #     case params[:model]
  #     when :manufacturer
  #       @items = Company.find(:all,:conditions => ['name LIKE ?', "#{params[:search]}%"])
  #     end
  #   end
  #   respond_to do |format|
  #     # Here is where you can specify how to handle the request for "/people.json"
  #     format.json { render :json => @items.to_json }
  #     end
  # end

  protected
  def user_active?
    unless current_user.nil? || current_user.active
      reset_session
    end
  end

  def configure_permitted_parameters
    # byebug
    # devise_parameter_sanitizer.for(:account_update) << :person
  end

  def get_scroll
    unless params[:relatedScrollElement].nil?
      @scrollElement = params.require('relatedScrollElement').to_s
      @scroll = params.require('scroll').to_i
    end
  end
end
