class MdcWebservice

  def initialize
    username = 'chiarcosso_ws'
    password = 'MfE3isk2Z0'
    useSharedDatabaseConnection = 0

    @endpoint = 'http://chiarcosso.mobiledatacollection.it/mdc_webservice/services/MdcServiceManager'

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:openSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:useSharedDatabaseConnection>#{useSharedDatabaseConnection}</ns3:useSharedDatabaseConnection><ns3:username>#{username}</ns3:username><ns3:password>#{password}</ns3:password></ns3:openSession></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    request.open_timeout = 10

    tries = 1
    while @sessionID.nil? do
      puts "Connecting (try #{tries}).."
      begin
        @sessionID = ::SessionID.new(HTTPI.post(request).body.match(/<ax21:sessionID>(.*?)<\/ax21:sessionID>/)[1].to_s)
      rescue
        tries += 1
      end
    end

  end

  def session_id
    @sessionID
  end

  def get_vacation_data(ops)
    self.begin_transaction

    data = Array.new
    dch = self.select_data_collection_heads(ops)
    unless dch[:data].nil?
      dch[:data].each_with_index do |ch,i|
        data[i] = VacationRequest.new(self.select_data_collection_rows(ch)[:data],self)
        # data[i][:data].each do |d|
        #   self.update_data_collection_rows_status(d.dataCollectionRowKey)
        # end
      end
    end
    self.commit_transaction
    self.end_transaction
    self.close_session

    return data
  end

  def get_data(ops)
    self.begin_transaction

    data = Array.new
    dch = self.select_data_collection_heads(ops)
    unless dch[:data].nil?
      dch[:data].each_with_index do |ch,i|
        data[i] = self.select_data_collection_rows(ch)
        data[i][:data].each do |d|
          self.update_data_collection_rows_status(d.dataCollectionRowKey)
        end
      end
    end
    self.commit_transaction
    self.end_transaction
    self.close_session

    return data
  end

  def close_session

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    HTTPI.post(request)
  end

  def begin_transaction

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:beginTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:beginTransaction></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    HTTPI.post(request)
  end

  def commit_transaction

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:commitTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:commitTransaction></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
# puts request.body
    HTTPI.post(request)
  end

  def end_transaction

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:endTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:endTransaction></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    HTTPI.post(request)
  end

  def select_data_collection_heads(ops)

    # ops => {
    #   applicationID: string,
    #   deviceCode: string,
    #   status: int
    # }
    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:selectDataCollectionHeads xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:applicationID>#{ops[:applicationID]}</ns3:applicationID><ns3:deviceCode>#{ops[:deviceCode]}</ns3:deviceCode><ns3:status>#{ops[:status]}</ns3:status></ns3:selectDataCollectionHeads></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    unpack_response(HTTPI.post(request))
  end

  def select_data_collection_rows(dataCollectionHead)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:selectDataCollectionRows xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{dataCollectionHead.xml}</ns3:selectDataCollectionRows></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    unpack_response(HTTPI.post(request).body)
  end

  def update_data_collection_rows_status(dataCollectionRowKey,status = 1)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:updateDataCollectionRowsStatus xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:keys>#{dataCollectionRowKey.xml}</ns3:keys><ns3:status>#{status}</ns3:status></ns3:updateDataCollectionRowsStatus></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    # puts request.body
    HTTPI.post(request)
  end

  def download_file(filename)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:downloadFile xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:fileName>#{filename}</ns3:fileName></ns3:downloadFile></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    HTTPI.post(request)
  end

  private

  def data_transform(definition)
    case definition[:data_type]
      when 'SessionID' then SessionID.new(definition[:sessionID])
      when 'DataCollectionHead' then DataCollectionHead.new(definition[:applicationCode],definition[:applicationID],definition[:collectionID],definition[:deviceCode])
      when 'DataCollectionRow' then DataCollectionRow.new(definition[:dataCollectionRow])
    end
  end

  def unpack_response(response)

      if response.class == HTTPI::Response
        response = response.body
      end
    # begin
      error = response.match(/<soapenv:Fault>.*?<\/soapenv:Fault/m)
      if error.nil?
        action = response.match(/<soapenv:Body><ns:(.*?)Response .*/m,1)[1]
        unless action == 'downloadFile'
          return_data = Array.new
          response.scan(/<ns:return .*?xsi:type="ax21:(.*?)"[^>]*>(.*?)<\/ns:return>/m) do |ret|
            return_data << {type: ret[0], body: ret[1]}
          end
          data = Array.new
          return_data.each do |r|
            tmp = Hash.new
            tmp[:data_type] = r[:type]
            r[:body].scan(/<ax21:([^>]*)>([^<]*)<\/ax21:[^>]*/).each do |match|
              tmp[match[0].to_sym] = match[1]
            end
            data << data_transform(tmp)
          end
        else
          tmp = response[/%PDF.*/m]
          # data = XMPR::XMP.new(tmp)
          File.open('tmp.pdf','w+') do |f|
            f.write(tmp.force_encoding('UTF-8'))
          end
        end
      else
        # byebug
      end
    # rescue
    #   action = 'Error'
    #   data = {body: response}
    # end
    return {action: action, data: data}

  end

end

class SessionID

  def initialize(id)
    @id = id
  end

  def id
    @id
  end

  def xml
    "<ns1:sessionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.id}</ns1:sessionID>"
  end
end

class DataCollectionHead
  def initialize(applicationCode, applicationID, collectionID, deviceCode)
    @applicationCode = applicationCode
    @applicationID = applicationID
    @collectionID = collectionID
    @deviceCode = deviceCode
  end

  def applicationCode
    @applicationCode
  end

  def applicationID
    @applicationID
  end

  def collectionID
    @collectionID
  end

  def deviceCode
    @deviceCode
  end

  def xml
    "<ns3:dataCollectionHead xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"><ns1:applicationCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.applicationCode}</ns1:applicationCode><ns1:applicationID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.applicationID}</ns1:applicationID><ns1:collectionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.collectionID}</ns1:collectionID><ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.deviceCode}</ns1:deviceCode></ns3:dataCollectionHead>"
  end
end

class DataCollectionRow

  def initialize(definition)
    @data = Array.new
    case definition.class.to_s
      when 'String' then
        definition.scan(/<ax21:(.*?)>(.*?)</).each do |r|
          if r[1].to_s.size > 0
            case key
              when :applicationCode then @applicationCode = value
              when :applicationID then @applicationID = value
              when :collectionID then @collectionID = value
              when :deviceCode then @deviceCode = value
              when :idd then @idd = value
              when :progressiveNo then @progressiveNo = value
              else
                @data << {r[0].to_sym => r[1]}
            end
          end
        end
      when 'Hash' then
        definition.each do |key,value|
          if value.to_s.size > 0
            case key
              when :applicationCode then @applicationCode = value
              when :applicationID then @applicationID = value
              when :collectionID then @collectionID = value
              when :deviceCode then @deviceCode = value
              when :idd then @idd = value
              when :progressiveNo then @progressiveNo = value
              else
                @data << {key => value}
            end
          end
        end
    end
    @dataCollectionRowKey = DataCollectionRowKey.new(@applicationCode,@collectionID,@deviceCode,@idd,@progressiveNo)
  end

  def applicationID
    @applicationID
  end

  def dataCollectionRowKey
    @dataCollectionRowKey
  end

  def data
    @data
  end

end

class DataCollectionRowKey

  def initialize(applicationCode,collectionID,deviceCode,idd,progressiveNo)
    @applicationCode = applicationCode
    @collectionID = collectionID
    @deviceCode = deviceCode
    @idd = idd
    @progressiveNo = progressiveNo
  end

  def xml
    "<ns2:dataCollectionRowKey xmlns:ns2=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"><ns1:applicationCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@applicationCode}</ns1:applicationCode><ns1:collectionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@collectionID}</ns1:collectionID><ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@deviceCode}</ns1:deviceCode></ns2:dataCollectionRowKey>"
  end

end

class VacationRequest

  #array of dataCollectionRows
  def initialize(dataCollectionRows, mdc = MdcWebservice.new)

    dataCollectionRows.each do |dcr|
      next if dcr.applicationID != 'FERIE'

      @type = 0
      @date = Date.new(dcr[:date])
      @device = dcr[:deviceCode]
      case dcr[:field_code]
        when 'date_from' then @date_from = Date.new(dcr[:extendedValue])
        when 'date_to' then @date_to = Date.new(dcr[:extendedValue])
        when 'time_from' then @time_from = Date.new(dcr[:extendedValue])
        when 'time_to' then @time_to = Date.new(dcr[:extendedValue])
      end
      puts dcr[:formCode]
      puts dcr[:progressiveno]
      if dcr[:formCode] == 'pdf_report' and dcr[:progressiveNo] == 3

        @form = mdc.download_file(dcr[:description])[/%PDF.*/m]
      end
    end


  end

  def send_mail
    HumanResourcesMailer.new.vacation_request(self)
  end

  def filename
    'test.pdf'
  end

  def form
    @form
  end

  def type
    'ferie'
  end

  def person
    @device
  end

  def date
    @date#.strftime('%d/%M/%Y')
  end

  def when
    "dal #{from} al #{to}"
  end

  def from
    case @type
    when 0 then @date_from.strftime("%D/%M/%Y")
    when 1 then @time_from.strftime("%H:%m:%s")
    end
  end

  def to
    case @type
    when 0 then @date_from.strftime("%D/%M/%Y")
    when 1 then @time_from.strftime("%H:%m:%s")
    end
  end
end
