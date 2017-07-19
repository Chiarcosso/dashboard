class WsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => :update_fares
  protect_from_forgery except: :update_fares


  def index
    mdc = MdcWebservice.new

    @results = Array.new
    Person.mdc.each do |p|
      r = mdc.get_fares_data({applicationID: 'FARES', deviceCode: p.mdc_user.upcase, status: 0})
      @results << r unless r.empty?
    end
    render 'mdc/index'
  end

  def close_fare
    mdc = MdcWebservice.new
    mdc.begin_transaction
    mdc.update_data_collection_rows_status(Base64.decode64(params.require(:data_collection_rows)))
    mdc.commit_transaction
    mdc.end_transaction
    mdc.close_session
    index
  end

  def update_fares
    driver = Person.find_by_complete_name(Base64.decode64(params.require(:driver))).first
    unless driver.nil?
      if driver.mdc_user.nil?
        @msg = "Messaggio non inviato. Targa: #{params[:VehiclePlateNumber]}, #{driver.complete_name} non ha un utente assegnato."
      else
        id = params.require(:id)
        msg = Base64.decode64(params.require('ChatMessage'))
        mdc = MdcWebservice.new

        mdc.delete_tabgen_by_selector([TabgenSelector.new({tabname: 'FARES', index: 0, value: id, deviceCode: ''})])
        mdc.insert_or_update_tabgen(Tabgen.new({deviceCode: "|#{driver.mdc_user.upcase}|", key: id, order: 0, tabname: 'FARES', values: [msg]}))
        mdc.send_push_notification_ext(["|#{driver.mdc_user.upcase}|"],[NotificationExt.new({collectionID: nil, doSync: true, playNotificationSound: true, message: msg})])
        mdc.commit_transaction
        mdc.end_transaction
        mdc.close_session
        @msg = "Messaggio inviato. Targa: #{params[:VehiclePlateNumber]}, #{driver.complete_name} (utente: #{driver.mdc_user})."
      end
    else
      @msg = "Messaggio non inviato. Targa: #{params[:VehiclePlateNumber]}, #{Base64.decode64(params.require(:driver))} non esiste."
    end

    render :partial => 'layouts/messages'
  end
end
