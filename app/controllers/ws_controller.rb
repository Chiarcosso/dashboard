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
    mdc.delete_tabgen_by_selector([TabgenSelector.new({tabname: 'FARES', index: 0, value: params.require(:id), deviceCode: ''})])
    Person.mdc.each do |p|
      mdc.send_push_notification([p.mdc_user],'Aggiornamento viaggi.')
    end
    # mdc.send_push_notification(['ALL'],'Aggiornamento viaggi.')
    # mdc.send_push_notification(Person.mdc.pluck(:mdc_user),'Aggiornamento viaggi.')
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
        Person.mdc.each do |p|
          mdc.send_push_notification([p.mdc_user],'Aggiornamento viaggi.') unless p == driver
        end
        mdc.send_push_notification([driver.mdc_user],msg)
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

  def print_pdf
    photos = Array.new
    mdc = MdcWebservice.new
    params.require(:photos).each do |p|
      p.sub!('http://chiarcosso.mobiledatacollection.it/','/var/lib/tomcat8/webapps/')
      photos << mdc.download_file(p).body[/Content-Type: image\/jpeg.?*\r\n\r\n(.?*)\r\n--MIMEBoundary/m,1].force_encoding("utf-8")
    end
    margins = 15
    pdf = Prawn::Document.new :filename=>'foo.pdf',
                          :page_size=> "A4",
                          :margin => margins

    photos.each do |p|
      file = File.open('tmp.jpg','w')
      file.write(p)
      file.close
      size = FastImage::size('tmp.jpg')

      if size[0] > size[1]
          image = MiniMagick::Image.new("tmp.jpg")
          image.rotate(-90)
      end
      pdf.image 'tmp.jpg', :fit => [595.28 - margins*2, 841.89 - margins*2]
    end
    respond_to do |format|
      format.pdf do
        send_data pdf.render, filename:
        "test.pdf",
        type: "application/pdf"
      end
    end
  end

end
