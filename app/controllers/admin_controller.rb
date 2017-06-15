class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :query_params, only: [:send_query]
  require "#{Rails.root}/app/models/mdc_webservice"
  include AdminHelper

  def soap

    ws = MdcWebservice.new
    @sessionID = ws.session_id.id
    puts @sessionID
    @results = Array.new
    @resuts = MdcWebservice.look_for(:vacation)
    # Person.mdc.each do |p|
    #   tmp = ws.get_vacation_data({applicationID: 'FERIE', deviceCode: p.mdc_user.upcase, status: 0})
    #   tmp.each do |r|
    #     r.send_mail unless r.data.nil?
    #     # byebug if r.data.nil?
    #   end
    #   @results += tmp
    # end
    # endpoint = 'http://chiarcosso.mobiledatacollection.it/mdc_webservice/services/MdcServiceManager'
    # @endpoint = 'http://chiarcosso.mobiledatacollection.it/mdc_webservice/services/MdcServiceManager'

    # endpoint = 'http://192.168.88.10:80/mdc_webservice/services/MdcServiceManager'
    # MDC_WSDL_ENDPOINT = {
    #   :uri => 'http://chiarcosso.mobiledatacollection.it/mdc_webservice/services/MdcServiceManager'
    # }
    # client  = Handsoap::Service.new
    # boundary = 'MIMEBoundary_'+SecureRandom.hex
    # client = Savon.client(
    #               :wsdl => endpoint+"?wsdl",
    #               # :ssl_verify_mode => :none,
    #               # :headers => {
    #               #   'content-type' => 'multipart/related;  boundary="'+boundary+'"; type="application/xop+xml";',
    #               #   'content-transfer-encoding' => 'binary',
    #               #   'content-ID' => '<0.955339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>',
    #               #   'type' => 'application/xop+xml'
    #               # },
    #               :multipart => true,
    #               # :pretty_print_xml => true,
    #               :endpoint => endpoint,
    #               :logger => Rails.logger,
    #               :log => true,
    #               :namespace => 'http://ws.dataexchange.mdc.gullivernet.com',
    #               :namespace_identifier => 'ns3',
    #               :open_timeout => 10,
    #               :read_timeout => 300,
    #               :namespaces => {
    #                   'xmlns:xsd' => 'http://ws.dataexchange.mdc.gullivernet.com',
    #                   'xmlns:ns1' => 'http://ws.dataexchange.mdc.gullivernet.com',
    #                   'xmlns:ns3' => 'http://ws.dataexchange.mdc.gullivernet.com'
    #                 }
    #               )
    #
    # @operations = Array.new
    #
    # client.operations.sort.each do |o|
    #   @operations << o.to_s
    # end

    # -- Operations list --
    #
    # begin_transaction
    # begin_transaction_with_isolation_level
    # check_configuration
    # close_session
    # commit_transaction
    # delete_tabgen
    # delete_tabgen_by_selector
    # download_file
    # echo
    # end_transaction
    # insert_or_update_tabgen
    # insert_or_update_tabgen_list
    # insert_tabgen
    # open_session
    # rollback_transaction_changes
    # select_application_gps_record
    # select_application_gps_records
    # select_data_collection_extra_heads
    # select_data_collection_extra_rows
    # select_data_collection_heads
    # select_data_collection_rows
    # select_device_gps_records
    # select_devices_by_alternative_code
    # select_devices_by_code
    # select_devices_by_username
    # select_tabgen
    # select_tabgen_by_selector
    # send_push_notification
    # send_push_notification_ext
    # send_same_push_notification_ext
    # send_same_push_notification_ext_raw
    # update_data_collection_extra_rows_status
    # update_data_collection_rows_status
    # update_device_reference
    # upload_file
    # upload_image

    # begin
    # print 'SOAP response (open_session): '
    # os_response = client.call(:open_session, message: {useSharedDatabaseConnection: 0, username: user, password: passwd},multipart: false)
    # # client.call(:open_session, message: {useSharedDatabaseConnection: 0, username: user, password: passwd})
    # puts '                           OK'
    # # puts 'SID'
    # # puts os_response
    # puts
    # rescue Savon::SOAPFault => error
    #   # puts Logger.methods.sort
    #   puts error.http.inspect
    #   puts "\n"
    #   puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+"\n"
    # end
    #
    # # @result = response
    # # @result = response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]
    # @results = Array.new
    # r = HTTPI.post(build_open_session(0, user, passwd))
    # byebug
    # @results[0] = Nokogiri::XML(HTTPI.post(build_open_session(0, user, passwd)).body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]) do |xml|
    #   xml.strict
    # end
    # @sessionID = ::SessionID.new(HTTPI.post(build_open_session(0, user, passwd)).body.match(/<ax21:sessionID>(.*?)<\/ax21:sessionID>/)[1].to_s)

    # puts @sessionID

    # request = HTTPI::Request.new
    # request.url = endpoint
    # request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:beginTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:beginTransaction></soapenv:Body></soapenv:Envelope>"
    # request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    # # request.body = "--#{boundary}\r\nContent-Type: application/xop+xml; charset=UTF-8; type=\"text/xml\"\r\nContent-Transfer-Encoding: binary\r\nContent-ID: <0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>\r\n\r\n<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>\r\n--#{boundary}--\r\n"
    # puts
    # puts request.inspect
    # response = HTTPI.post(build_begin_transaction(@sessionID))
    # puts response.inspect
    # @results[1] = response

    # response = HTTPI.post(build_select_data_collection_heads(@sessionID,{applicationID: 'FERIE', deviceCode: 'T2', status: 0}))
    # puts response.inspect
    # collectionHeads = unpack_response(response)

    # collectionHeads[:data].each_with_index do |ch,i|
    #   response = HTTPI.post(build_select_data_collection_rows(@sessionID,data_transform(ch)))
    #   @results[i] = response
    # end
    # response = ws.get_data({applicationID: 'FERIE', deviceCode: 'T2', status: 0})
    # @results[0] = response

    # filenames = response.body.scan(/>([^>]*?.pdf)<\//)
    # filenames.each_with_index do |fn,i|
    #   req = build_download_file(@sessionID,fn[0])
    #   puts fn
    #   response = HTTPI.post(req)
    #   @results[i+1] = response
    # end


    # response = HTTPI.post(build_end_transaction(@sessionID))
    # puts response.inspect
    # @results[3] = response

    # response = HTTPI.post(build_close_session(@sessionID))
    # puts response.inspect
    # @results[4] = response

    # request = HTTPI::Request.new
    # request.url = endpoint
    # request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:selectDataCollectionHeads xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId><ns3:applicationID>FERIE</ns3:applicationID><ns3:deviceCode>T1</ns3:deviceCode><ns3:status>0</ns3:status></ns3:selectDataCollectionHeads></soapenv:Body></soapenv:Envelope>"
    # request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    # # request.body = "--#{boundary}\r\nContent-Type: application/xop+xml; charset=UTF-8; type=\"text/xml\"\r\nContent-Transfer-Encoding: binary\r\nContent-ID: <0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>\r\n\r\n<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>\r\n--#{boundary}--\r\n"
    # puts
    # puts request.inspect
    # response = HTTPI.post(request)
    # puts response.inspect
    # @results[2] = response
    #
    # request = HTTPI::Request.new
    # request.url = endpoint
    # request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:endTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:endTransaction></soapenv:Body></soapenv:Envelope>"
    # request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    # # request.body = "--#{boundary}\r\nContent-Type: application/xop+xml; charset=UTF-8; type=\"text/xml\"\r\nContent-Transfer-Encoding: binary\r\nContent-ID: <0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>\r\n\r\n<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>\r\n--#{boundary}--\r\n"
    # puts
    # puts request.inspect
    # response = HTTPI.post(request)
    # puts response.inspect
    # @results[3] = response
    #
    # request = HTTPI::Request.new
    # request.url = endpoint
    # request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>"
    # request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    # # request.body = "--#{boundary}\r\nContent-Type: application/xop+xml; charset=UTF-8; type=\"text/xml\"\r\nContent-Transfer-Encoding: binary\r\nContent-ID: <0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>\r\n\r\n<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId><ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@sessionID}</ns1:sessionID></ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>\r\n--#{boundary}--\r\n"
    # puts
    # puts request.inspect
    # response = HTTPI.post(request)
    # puts response.inspect
    # @results[4] = response
    # begin
    # print 'SOAP response (begin_transaction): '
    # bt_response = client.call(:close_session, message: {'ns3:sessionID': { 'ns1:sessionID': @sessionID }}, :attributes => {
    #   'content-type' => 'multipart/related;  boundary="'+boundary+'"; type="application/xop+xml";',
    #   'content-transfer-encoding' => 'binary',
    #   'content-ID' => '<0.'+boundary+'@apache.org>',
    #   'type' => 'application/xop+xml'
    # },multipart: true)
    # # bt_response = client.call(:echo, message: {'sessionID': {'ns2:sessionID': @sessionID}, applicationID: 'FERIE', deviceCode: 'T2', status: 0}, :multipart => true)
    # # bt_response = client.call(:echo, message: {'text': 'blabla'}, :multipart => true)
    # puts '                           OK'
    # rescue Savon::SOAPFault => error
    #   # puts Logger.methods.sort
    #   puts error.http.inspect
    #   # raise
    # end
    # puts bt_response
    # puts "\n"
    # puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+"\n"
    # # @result = response
    # # @result = response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]
    #
    # @results[1] = Nokogiri::XML(bt_response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]) do |xml|
    #   # xml.strict
    # end
    # @results[1].remove_namespaces!

    # begin
    # print 'SOAP response (select_data_collection_heads): '
    # bt_response = client.call(:select_data_collection_heads, message: {'sessionID': @sessionID, applicationID: 'FERIE', deviceCode: 'T2', status: 0}, :attributes => { 'SessionID' => { "xsi:type" => "ax21:SessionID" } })
    # # bt_response = client.call(:select_data_collection_heads, message: {'ax22:SessionID': @sessionID, applicationID: 'FERIE', deviceCode: 'T2', status: 0})
    # puts '                           OK'
    # rescue Savon::SOAPFault => error
    #   # puts Logger.methods.sort
    #   puts error.http.inspect
    #   # raise
    # end
    #
    # puts "\n"
    # puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+"\n"
    # # @result = response
    # # @result = response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]
    #
    # @results[1] = Nokogiri::XML(bt_response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]) do |xml|
    #   xml.strict
    # end
    # @results[1].remove_namespaces!
    #
    # begin
    # print 'SOAP response (close_session): '
    # cs_response = client.call(:close_session, message: {sessionID: @sessionID})
    # puts '                           OK'
    # rescue Savon::SOAPFault => error
    #   # puts Logger.methods.sort
    #   puts error.http.inspect
    #   # raise
    # end
    #
    # puts "\n"
    # puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+"\n"
    # # @result = response
    # # @result = response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]
    #
    # @results[2] = Nokogiri::XML(cs_response.http.body.match(/.*<?xml version.*?>[ ]*(<.*>)/m)[1]) do |xml|
    #   xml.strict
    # end
    # @results[2].remove_namespaces!
  end

  def queries
    @list = Query.where(:model_class => 'Vehicle').first.nil?? '' : Query.where(:model_class => 'Vehicle').first.query
    render 'admin/query'
  end

  def send_query_vehicles
    @result = RestClient.get "http://10.0.0.102/queries/vehicles.php"
    @result = JSON.parse @result.body
    @results = Array.new
    @type = :vehicles
    @result.each do |row|
      row['manufacturer'].gsub!(/\w+/, &:capitalize)
      row['property'].gsub!(/\w+/, &:capitalize)
      row['type'].first.upcase!
      row['vat'].upcase!
      platenumber = row['plate'].upcase.tr('. *','')

      plates = VehicleInformation.where(information: row['plate']).order(date: :asc)
      plates.each do |p|
        p.information = platenumber
        p.save
      end



      manufacturer = Company.find_by(name: row['manufacturer'])
      if manufacturer.nil?
        manufacturer = Company.create(name: row['manufacturer'])
      end
      property = Company.find_by(vat_number: row['vat'])
      if property.nil?
        property = Company.create(name: row['property'], vat_number: row['vat'])
      end
      vehicle_type = VehicleType.find_by(name: row['type'])
      if vehicle_type.nil?
        vehicle_type = VehicleType.create(name: row['type'])
      end
      model = VehicleModel.find_by(name: row['model'])
      if model.nil?
        model = VehicleModel.create(name: row['model'], vehicle_type: vehicle_type, manufacturer: manufacturer)
      end
      plate = VehicleInformation.where(information: platenumber).order(date: :asc).last
      unless plate.nil?
        vehicle = Vehicle.find(plate.vehicle.id)
      end
      if vehicle.nil?
        registration = row['registrationDate'].to_i < 1970 ? nil : Date.new(row['registrationDate'].to_i,1,1)
        vehicle = Vehicle.create(dismissed: (row['dismissed'] == '0'), mileage: row['mileage'], registration_date: registration, property: property, model: model)
        plate = VehicleInformation.create(information_type: VehicleInformation.types['Targa'], information: row['plate'], date: Date.current, vehicle: vehicle)
        chassis = VehicleInformation.create(information_type: VehicleInformation.types['N. di telaio'], information: row['chassis'], date: Date.current, vehicle: vehicle)
        @results << vehicle
      end

    end
    render 'admin/query'
  end

  def send_query_people
    @result = RestClient.get "http://10.0.0.102/queries/people.php"
    @result = JSON.parse @result.body
    @results = Array.new
    @type = :people
    @result.each do |row|
      # @results << row
      if row['company'] == 'A'
        company = Company.find_by(name: 'Autotrasporti Chiarcosso s.r.l.')
      end
      if row['company'] == 'T'
        company = Company.find_by(name: 'Trans Est s.r.l.')
      end

      if (row["name"] == row["surname"])
        names = row["name"].split
        row['surname'] = ''
        row['name'] = names[names.size-1]

        (names.size-1).times do |index|
          row['surname'] += names[index]
          unless index == names.size-1
            row["surname"] += ' '
          end
        end
      end
      person = Person.where(:name => row['name'], :surname => row['surname']).first
      role = CompanyRelation.find_by(name: row['role'])
      if role.nil?
        role = CompanyRelation.create(name: row['role'])
      end
      if person.nil?
        person = Person.create(name: row['name'], surname: row['surname'])
      end
      rel = CompanyPerson.where(person: person, company_relation: role, company: company).first
      if rel.nil?
        CompanyPerson.create(person: person, company_relation: role, company: company)
      end
      @results << person
    end

    render 'admin/query'
  end

  private

  def query_params
    params.require(:model_class)
    # case params.require(:model_class)
    # when 'Vehicle'
    #   @query = %{SELECT Targa AS plate, f.RagioneSoc AS property, anno AS registrationDate,
    #           Marca AS manufacturer, Modello AS model, Telaio AS chassis, Km AS mileage,
    #           FROM Veicoli v
    #           INNER JOIN Fornitori f ON f.IDFornitore = v.IDFornitore
    #           INNER JOIN Tipo t ON t.IDTipo = v.IDTipo
    #         }
    # end
  end

  def authorize_admin
    unless current_user.has_role? :admin
      redirect_to 'home/agenda'
    end
  end

end
