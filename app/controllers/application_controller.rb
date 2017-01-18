class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!
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

end
