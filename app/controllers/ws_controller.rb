class WsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => :update_fares
  protect_from_forgery except: :update_fares


  def update_fares
    puts params.inspect
    driver = Person.where("'surname+' '+name' = '#{Base64.decode64(params.require(:driver))}'").first
    @msg = "Messaggio inviato. Targa: #{params[:VehiclePlateNumber]}, #{driver.complete_name}."
    render :partial => 'layouts/messages'
  end
end
