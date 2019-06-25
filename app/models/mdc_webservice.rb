class MdcWebservice

  def initialize

    username = ENV['MDC_USERNAME']
    password = ENV['MDC_PASSWD']
    useSharedDatabaseConnection = 0

    # addr = 'chiarcosso.mobiledatacollection.it'
    addr = "outpost.chiarcosso"
    # addr = '192.168.88.13'
    @endpoint = 'http://'+addr+'/mdc_webservice/services/MdcServiceManager'
    @media_address = 'http://'+addr+'/server_chiarcosso/mediaanswers/'

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:openSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:useSharedDatabaseConnection>#{useSharedDatabaseConnection}</ns3:useSharedDatabaseConnection><ns3:username>#{username}</ns3:username><ns3:password>#{password}</ns3:password></ns3:openSession></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    request.open_timeout = 3

    tries = 1
    while @sessionID.nil? and tries < 10 do
      puts "Connecting (try #{tries}).."
      begin
        @sessionID = ::SessionID.new(HTTPI.post(request).body.match(/<ax21:sessionID>(.*?)<\/ax21:sessionID>/)[1].to_s)
      rescue
        tries += 1
        sleep 2
      end
    end

  end

  def media_address
    @media_address
  end

  def self.look_for(what)
    mdc = MdcWebservice.new
    results = Array.new
    case what
    when :report then

      MdcUser.assigned.each do |p|

        puts "REPORTS Search for user #{p.user.upcase} (#{p.complete_name})"
        mdc.get_report_data({applicationID: 'REPORTS', deviceCode: p.user.upcase, status: 0}).each do |r|

          r.register unless r.data.nil?
            # r.send_mail unless r.data.nil?

          results << r
        end

      end
      when :vacation then
        MdcUser.assigned.each do |p|
          puts "VACATION Search for user #{p.user.upcase} (#{p.complete_name})"
          mdc.get_vacation_data({applicationID: 'FERIE', deviceCode: p.user.upcase, status: 0}).each do |r|

              r.send_mail unless r.data.nil?

            results << r
          end
        end
      when :gear then
        begin
          gear = nil
          user = nil
          MdcUser.assigned.each do |p|
            puts "GEAR Search for user #{p.user.upcase} (#{p.complete_name})"
            user = "GEAR Search for user #{p.user.upcase} (#{p.complete_name})"
            mdc.get_gear_data({applicationID: 'GEAR', deviceCode: p.user.upcase, status: 0}).each do |r|
                gear = r
                r.send_mail unless r.data.nil?

              results << r
            end
          end
        rescue Exception => e
          error = user+"\n\n"+r.inspect+"\n\n"+e.message+"\n\n"+e.backtrace.join("\n")
          ErrorMailer.error_report(error,"Mail dotazione - SGN nr. #{sgn['Protocollo']}").deliver_now
        end
    end
    mdc.close_session
    return results
  end

  def session_id
    @sessionID
  end

  def get_fares_data(ops)
    self.begin_transaction

    data = Array.new
    dch = self.select_data_collection_heads(ops)
    unless dch[:data].nil?
      dch[:data].each_with_index do |ch,i|
        dd = FareDocuments.new(self.select_data_collection_rows(ch)[:data],self)
        if dd.date > Time.now - 2.months
          data[i] = dd
        else
          self.update_data_collection_rows_status(self.select_data_collection_rows(ch)[:data])
        end

      end
    end
    self.commit_transaction
    self.end_transaction
    # self.close_session
    return data
  end

  def get_report_data(ops)
    self.begin_transaction

    data = Array.new

    dch = self.select_data_collection_heads(ops)

    unless dch[:data].nil?
      dch[:data].each_with_index do |ch,i|
        data[i] = ReportRequest.new(self.select_data_collection_rows(ch)[:data],self)

        # data[i][:data].each do |d|
        #   self.update_data_collection_rows_status(d.dataCollectionRowKey)
        # end
      end
    end

    self.commit_transaction
    self.end_transaction
    # self.close_session
    return data
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
    # self.close_session
    return data
  end

  def get_gear_data(ops)
    self.begin_transaction

    data = Array.new
    dch = self.select_data_collection_heads(ops)
    unless dch[:data].nil?
      dch[:data].each_with_index do |ch,i|
        data[i] = GearRequest.new(self.select_data_collection_rows(ch)[:data],self)
        # data[i][:data].each do |d|
        #   self.update_data_collection_rows_status(d.dataCollectionRowKey)
        # end
      end
    end
    self.commit_transaction
    self.end_transaction
    # self.close_session
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
    # self.close_session

    return data
  end

  def close_session

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:closeSession xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:closeSession></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def begin_transaction

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:beginTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:beginTransaction></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def commit_transaction

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:commitTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:commitTransaction></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def end_transaction

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:endTransaction xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId></ns3:endTransaction></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def send_push_notification_ext(deviceCodes,message,collectionID)

    dc = ''
    pne = ''
    deviceCodes.each do |d|
      dc += "<ns3:deviceList><ns1:username xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{d.user.downcase}</ns1:username></ns3:deviceList>"
      pne += NotificationExt.new(collectionID: collectionID, doSync: 1, playNotificationSound: 0, message: message).xml
    end
    # nots = ''
    # message.each do |n|
    #   nots += n.xml
    # end

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:sendPushNotificationExt xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{dc}<ns3:notificationExtList>#{pne}</ns3:notificationExtList></ns3:sendPushNotificationExt></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def send_same_push_notification_ext(deviceCodes,message)

    dc = ''
    pne = ''
    deviceCodes.each do |d|
      dc += "<ns3:deviceList><ns1:username xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{d.user.downcase}</ns1:username></ns3:deviceList>"
    end
    # nots = ''
    # message.each do |n|
    #   nots += n.xml
    # end

    pne = NotificationExt.new(collectionID: nil, doSync: 1, playNotificationSound: 0, message: message)
    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:sendSamePushNotificationExt xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{dc}<ns3:notificationExt>#{pne.xml}</ns3:notificationExt></ns3:sendSamePushNotificationExt></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def send_push_notification(deviceCodes,message)

    dc = ''
    deviceCodes.each do |d|
      dc += "<ns3:deviceList><ns1:username xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{d.user.downcase}</ns1:username></ns3:deviceList>"
    end
    # nots = ''
    # message.each do |n|
    #   nots += n.xml
    # end
    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:sendPushNotification xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{dc}<ns3:messageList>#{message}</ns3:messageList></ns3:sendPushNotification></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def insert_or_update_tabgen(tabgen)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:insertOrUpdateTabgen xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{tabgen.xml}</ns3:insertOrUpdateTabgen></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    puts request.body
    resp = HTTPI.post(request)
    puts resp.body
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def select_tabgen(tabgen)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:selectTabgen xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{tabgen.xml(true)}</ns3:selectTabgen></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    puts request.body
    resp = HTTPI.post(request)
    puts resp.body
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def delete_tabgen_by_selector(selectors)

    sel = ''
    selectors.each do |s|
      sel += s.xml
    end
    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:deleteTabgenBySelector xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{sel}</ns3:deleteTabgenBySelector></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    puts request.body
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    puts resp.body
    resp
  end

  def select_data_collection_heads(ops)

    # ops => {
    #   applicationID: string,
    #   deviceCode: string,
    #   status: int
    # }
    ops[:deviceCode] = "|#{MdcUser.assigned.map{ |u| u.user.upcase }.join('|')}|" if ops[:deviceCode].nil?
    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:selectDataCollectionHeads xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:applicationID>#{ops[:applicationID]}</ns3:applicationID><ns3:deviceCode>#{ops[:deviceCode]}</ns3:deviceCode><ns3:status>#{ops[:status]}</ns3:status></ns3:selectDataCollectionHeads></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    unpack_response(resp.body)
  end

  def select_data_collection_rows(dataCollectionHead)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:selectDataCollectionRows xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{dataCollectionHead.xml}</ns3:selectDataCollectionRows></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    unpack_response(resp.body)
  end

  def update_data_collection_rows_status(dataCollectionRows,status = 1)
    if dataCollectionRows.is_a? String
      keys = dataCollectionRows
    else
      keys  = ''
      dataCollectionRows.each do |dcr|
        keys += "<ns3:keys>#{dcr.dataCollectionRowKey.xml}</ns3:keys>"
      end
    end
    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:updateDataCollectionRowsStatus xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId>#{keys}<ns3:status>#{status}</ns3:status></ns3:updateDataCollectionRowsStatus></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  def download_file(filename)

    request = HTTPI::Request.new
    request.url = @endpoint
    request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:downloadFile xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:fileName>#{filename}</ns3:fileName></ns3:downloadFile></soapenv:Body></soapenv:Envelope>"
    request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    special_logger.info(request.body+"\n")
    resp = HTTPI.post(request)
    special_logger.info(resp.body+"\n\n")
    resp
  end

  private

  def special_logger
    @@special_logger ||= Logger.new("#{Rails.root}/log/mdc_webservice.log")
  end

  def data_transform(definition)
    # byebug if definition[:data_type]=='DataCollectionRow'
    case definition[:data_type]
      when 'SessionID' then SessionID.new(definition[:sessionID])
      when 'DataCollectionHead' then DataCollectionHead.new(definition[:applicationCode],definition[:applicationID],definition[:collectionID],definition[:deviceCode])
      when 'DataCollectionRow' then DataCollectionRow.new(definition)
    end
  end

  def unpack_response(response)

      if response.class == HTTPI::Response
        response = response.body
      end
    # begin
      error = response.match(/<soapenv:Fault>.*?<\/soapenv:Fault>/m)
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
          # byebug
          tmp = response[/%PDF.*/m]
          # data = XMPR::XMP.new(tmp)
          File.open('tmp.pdf','w+') do |f|
            f.write(tmp.force_encoding('UTF-8'))
          end
        end
      else
        puts error
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

class NotificationExt
  def initialize(options)
    @collectionID = options[:collectionID]
    @doSync = options[:doSync]
    @playNotificationSound = options[:playNotificationSound]
    @message = options[:message]
  end

  def collectionID
    @collectionID
  end

  def doSync
    @doSync
  end

  def playNotificationSound
    @playNotificationSound
  end

  def message
    @message
  end

  def xml
    "<ns3:notificationExt xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"><ns1:collectionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.collectionID}</ns1:collectionID><ns1:message xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.message}</ns1:message><ns1:playNotificationSound xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.playNotificationSound}</ns1:playNotificationSound><ns1:sync xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.doSync}</ns1:sync></ns3:notificationExt>"
  end
end

class Tabgen
  def initialize(options)
    @key = options[:key]
    @order = options[:order]
    @tabname = options[:tabname]
    @values = options[:values]
    @deviceCode = options[:deviceCode]
  end

  def key
    @key
  end

  def order
    @order
  end

  def tabname
    @tabname
  end

  def deviceCode
    @deviceCode
  end

  def deviceCodeXml
    if @deviceCode.nil?
      str = "<ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"></ns1:deviceCode>"
    else
      str = ''
      @deviceCode.split('|').each do |dc|
        str += "<ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{dc}</ns1:deviceCode>" unless dc == ''
      end
    end


    str
    "<ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@deviceCode}</ns1:deviceCode>"
  end

  def xml_values
    xml = ''
    c = 1
    vs = Array.new
    20.times do
      n = c == 1 ? '' : c.to_s
      vs << "<ns1:value#{n} xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@values[c-1]}</ns1:value#{n}>"
      c += 1
    end
    vs.sort.each do |v|
      xml += v
    end
    xml
  end

  def xml(no_values = false)
    "<ns3:tabgen xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.deviceCodeXml}<ns1:key xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.key}</ns1:key><ns1:order xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.order}</ns1:order><ns1:tabname xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.tabname}</ns1:tabname>#{no_values ? '' : self.xml_values}</ns3:tabgen>"
  end
end

class TabgenSelector
  def initialize(options)
    @tabname = options[:tabname]
    @value = options[:value]
    @index = options[:index]
    @deviceCode = options[:deviceCode]
  end

  def value
    @value
  end

  def index
    @index
  end

  def tabname
    @tabname
  end

  def deviceCode
    @deviceCode
  end

  def deviceCodeXml
    str = ''
    # @deviceCode.split('|').each do |dc|
    #   str += "<ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{dc}</ns1:deviceCode>"
    # end
    str = "<ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@deviceCode}</ns1:deviceCode>" unless @deviceCode.nil?
    str
  end

  def xml
    "<ns3:tabgenSelector xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"><ns1:tabname xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.tabname}</ns1:tabname><ns1:index xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{self.index}</ns1:index><ns1:value xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{value}</ns1:value>#{self.deviceCodeXml}</ns3:tabgenSelector>"
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
    @data = Hash.new
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
                # @data << {r[0].to_sym => r[1]}
                @data[r[0].to_sym] = r[1]
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
              when :progressiveNo then @progressiveNo = value.to_i
              else
                # @data << {key => value}
                @data[key.to_sym] = value
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

  def deviceCode
    @deviceCode
  end

  def progressiveNo
    @progressiveNo
  end

  def xml
    # "<ns2:dataCollectionRowKey xmlns:ns2=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\"><ns1:applicationCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@applicationCode}</ns1:applicationCode><ns1:collectionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@collectionID}</ns1:collectionID><ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@deviceCode}</ns1:deviceCode></ns2:dataCollectionRowKey>"
    "<ns1:applicationCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@applicationCode}</ns1:applicationCode><ns1:collectionID xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@collectionID}</ns1:collectionID><ns1:deviceCode xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@deviceCode}</ns1:deviceCode><ns1:idd xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@idd}</ns1:idd><ns1:progressiveNo xmlns:ns1=\"http://ws.dataexchange.mdc.gullivernet.com/xsd\">#{@progressiveNo}</ns1:progressiveNo>"
  end

end

class FareDocuments

  def initialize(dataCollectionRows, mdc)

    @dataCollectionRows = dataCollectionRows
    @mdc = mdc
    @data = Hash.new
    @data[:photos] = Array.new
    @dataCollectionRows.each do |dcr|

      next if dcr.applicationID != 'FARES'
      @type = 0


      @date = Date.strptime(dcr.data[:date], '%Y%m%d')
      @dataCollectionRowKey = dcr.dataCollectionRowKey
      case dcr.data[:formCode]
        when 'fare' then @data[:id] = dcr.data[:value]
        when 'photos' then
          # file = mdc.download_file(dcr.data[:description]).body[/Content-Type: image\/jpeg.?*\r\n\r\n(.?*)\r\n--MIMEBoundary/m,1]
          # @data[:photos] << file.force_encoding("utf-8") unless file.nil?
          img = dcr.data[:description][/\/.*?([^\/]*.$)/,1] unless dcr.data[:description].nil?
          @data[:photos] << mdc.media_address+img unless img.nil?
      end

      # if dcr.data[:formCode] == 'pdf_report' and dcr.dataCollectionRowKey.progressiveNo == 2
      #    @data[:form] = mdc.download_file(dcr.data[:description]).body[/%PDF.*?%%EOF/m].force_encoding("utf-8")
      # end

    end

    self.register_photos
    # byebug if @data[:id].nil? || @data[:id] == ''
    # @data = nil if @data[:date_from].nil? or @data[:date_to].nil?
    # mdc.update_data_collection_rows_status(dataCollectionRows) unless @data.nil?
  end

  def date
    @date
  end

  def data
    @data
  end

  def definition
    request = HTTPI::Request.new
    request.url = "http://portale.chiarcosso/invia-viaggi/rest.php?id=#{self.id}"
    # request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:sendPushNotificationExt xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:deviceList>#{dc}</ns3:deviceList><ns3:notificationExtList>#{nots}</ns3:notificationExtList></ns3:sendPushNotificationExt></soapenv:Body></soapenv:Envelope>"
    # request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}

    HTTPI.post(request).body
  end

  def dataCollectionRows
    @dataCollectionRows
  end

  def id
    @data[:id]
  end

  def user
    # Person.find_by_mdc_user(@dataCollectionRowKey.deviceCode)
    MdcUser.where(user: @dataCollectionRowKey.deviceCode).first
  end

  def photos
    # tmp = Array.new
    # @data[:photos].each_with_index do |p,i|
    #   fh = File.open("public/foto/#{self.id}-#{i}.jpg",'w')
    #   fh.write(p)
    #   fh.close
    #   tmp << "/foto/#{self.id}-#{i}.jpg"
    # end
    # tmp
    @data[:photos]
  end

  def register_photos
    # Write photos
    unless @data[:photos].nil?

      query = "select  CONVERT(VARCHAR(6), data, 12) as data from giornale where idposizione = #{self.id};"

      client = MssqlReference::get_client
      fare = client.execute(query)
      path = "DocumentiViaggio/#{fare.first['data']}"
      client.close

      cpath = "#{ENV['RAILS_FARE_PHOTOS_PATH']}/#{path}/"
      # rpath = "FotoSegnalazioni\\#{path.gsub('/',"\\")}\\#{report.sent_at.strftime("%Y%m%d")}"
      # url = "/FotoViaggio/#{path}/"
      `mkdir -p #{cpath.gsub(' ','\ ')}/`

      @data[:photos].each do |photo|

        # Download file
        begin
          data = open(photo).read
          fh = File.open("tmp_fare_photo.jpg",'wb')
          fh.write(data)
          fh.close
        rescue Exception => e
          next
        end

        # Check whether the photo was already registered
        already_downloaded = false
        Dir.glob("#{cpath}/*.jpg").each do |img|
          already_downloaded = true if FileUtils.compare_file(img,"tmp_fare_photo.jpg")
        end
        next if already_downloaded

        # Check whether filename already exists
        serial = 1
        ext = File.extname(photo)

        while File.file? "#{cpath}/#{self.id}_#{serial.to_s.rjust(2,"0")}#{ext}" do
          serial += 1
        end
         filename = "#{self.id}_#{serial.to_s.rjust(2,"0")}#{ext}"

        # Write file
        fh = File.open("#{cpath}/#{filename}",'wb')
        fh.write(data)
        fh.close

        # url = ''
        # MdcReportImage.create(mdc_report: report, url: "#{url}/#{filename}", path: "#{cpath}/#{filename}")

      end
      # report.update(description: "#{report.description}\n#{rpath}")
    end
  end
end

class ReportRequest

  def initialize(dataCollectionRows, mdc)

    @dataCollectionRows = dataCollectionRows
    @mdc = mdc
    @data = Hash.new
    @data[:images] = Array.new
    @dataCollectionRows.each do |dcr|

      next if dcr.applicationID != 'REPORTS'
      @type = 0


      @date = Date.strptime(dcr.data[:date], '%Y%m%d')
      @dataCollectionRowKey = dcr.dataCollectionRowKey
      case dcr.data[:formCode]
      when 'type' then
        @data[:type] = dcr.data[:value] || dcr.data[:extendedValue]
      when 'description' then
        @data[:description] = dcr.data[:value] || dcr.data[:extendedValue]
      when 'plate' then
        @data[:vehicle] = Vehicle.find(dcr.data[:value].to_i) unless dcr.data[:value].nil?
      when 'photos' then
        # file = mdc.download_file(dcr.data[:description]).body[/Content-Type: image\/jpeg.?*\r\n\r\n(.?*)\r\n--MIMEBoundary/m,1]
        # @data[:photos] << file.force_encoding("utf-8") unless file.nil?
        img = dcr.data[:description][/\/.*?([^\/]*.$)/,1] unless dcr.data[:description].nil?
        @data[:images] << mdc.media_address+img unless img.nil?
      end
      @data[:sent_at] = Time.strptime(dcr.data[:date]+dcr.data[:time],"%Y%m%d%H%M%S") unless dcr.data[:date].nil?
      # if dcr.data[:formCode] == 'pdf_report' and dcr.dataCollectionRowKey.progressiveNo == 2
      #    @data[:form] = mdc.download_file(dcr.data[:description]).body[/%PDF.*?%%EOF/m].force_encoding("utf-8")
      # end

    end
    # byebug if @data[:id].nil? || @data[:id] == ''
    # @data = nil if @data[:date_from].nil? or @data[:date_to].nil?
    # mdc.update_data_collection_rows_status(dataCollectionRows) unless @data.nil?
  end

  def data
    @data
  end

  def definition
    # request = HTTPI::Request.new
    # request.url = "http://portale.chiarcosso/invia-viaggi/rest.php?id=#{self.id}"
    # request.body = "<?xml version='1.0' encoding='UTF-8'?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"><soapenv:Body><ns3:sendPushNotificationExt xmlns:ns3=\"http://ws.dataexchange.mdc.gullivernet.com\"><ns3:sessionId>#{@sessionID.xml}</ns3:sessionId><ns3:deviceList>#{dc}</ns3:deviceList><ns3:notificationExtList>#{nots}</ns3:notificationExtList></ns3:sendPushNotificationExt></soapenv:Body></soapenv:Envelope>"
    # request.headers = {'Content-type': 'application/xop+xml; charset=UTF-8; type=text/xml', 'Content-Transfer-encoding': 'binary', 'Content-ID': '<0.155339ee45be667b7fb6bd4a93dfbdb675d93cb4dc97da9b@apache.org>'}
    @data[:description]
    # HTTPI.post(request).body
  end

  def dataCollectionRows
    @dataCollectionRows
  end

  def type
    @data[:type]
  end

  def description
    @data[:description]
  end

  def vehicle
    @data[:vehicle]
  end

  def sent_at
    @data[:sent_at]
  end

  def offices
    case self.type.downcase
    when 'incidente' then
      return [:hr,:logistics,:maintenance]
    when 'infortunio' then
      return [:hr,:logistics]
    when 'info' then
      return [:hr,:logistics]
    when 'sosta_prolungata' then
      return [:logistics]
    when 'avaria_mezzo' then
      return [:maintenance]
    when 'guasto' then
      return [:maintenance]
    when 'danno' then
      return [:maintenance]
    when 'furto' then
      return [:hr,:maintenance,:logistics]
    when 'altro' then
      return [:hr,:maintenance,:logistics]
    when 'contravvenzione' then
      return [:logistics,:maintenance]
    when 'attrezzatura' then
      return [:logistics,:maintenance]
    when 'dpi' then
      return [:logistics,:hr]
    else
      return []
    end
  end

  def register
    begin

      data = {
        mdc_user: self.user,
        report_type: self.type,
        description: self.description || '',
        vehicle: self.vehicle,
        hr: MdcReport.offices(self.type).include?(:hr),
        maintenance: MdcReport.offices(self.type).include?(:maintenance),
        logistics: MdcReport.offices(self.type).include?(:logistics),
        sent_at: self.sent_at
      }

      report = MdcReport.create(data)

      # Write photos
      unless @data[:images].nil?

        if report.vehicle.nil?
          path = "Sede"
        else
          vehicle = report.vehicle
          path = "Mezzi/#{vehicle.mssql_references.count > 0 ? vehicle.mssql_references.first.remote_object_id : '0000'} - #{vehicle.split_plate}"
        end
        cpath = "#{ENV['RAILS_REPORT_PHOTOS_PATH']}/#{path}/#{report.sent_at.strftime("%Y%m%d")}"
        rpath = "FotoSegnalazioni\\#{path.gsub('/',"\\")}\\#{report.sent_at.strftime("%Y%m%d")}"
        url = "/FotoSegnalazioni/#{path}/#{report.sent_at.strftime("%Y%m%d")}"
        `mkdir -p #{cpath.gsub(' ','\ ')}/`

        @data[:images].each do |photo|

          # Check whether filename already exists
          serial = 1
          ext = File.extname(photo)

          while File.file? "#{cpath}/foto_#{serial.to_s.rjust(2,"0")}#{ext}" do
            serial += 1
          end
           filename = "foto_#{serial.to_s.rjust(2,"0")}#{ext}"

          # Download and write file
          data = open(photo).read
          fh = File.open("#{cpath}/#{filename}",'wb')
          fh.write(data)
          fh.close

          # url = ''
          MdcReportImage.create(mdc_report: report, url: "#{url}/#{filename}", path: "#{cpath}/#{filename}")

        end
        report.update(description: "#{report.description}\n#{rpath}")
      end

      @mdc.update_data_collection_rows_status(dataCollectionRows) unless @data.nil?
    rescue Exception => e
      report_logger.error("#{e.message}\n\n#{e.backtrace.join("\n")}")
      @mdc.update_data_collection_rows_status(dataCollectionRows) unless @data.nil?
    end
  end

  def user
    # Person.find_by_mdc_user(@dataCollectionRowKey.deviceCode)
    MdcUser.where(user: @dataCollectionRowKey.deviceCode).first
  end

  def images
    # tmp = Array.new
    # @data[:photos].each_with_index do |p,i|
    #   fh = File.open("public/foto/#{self.id}-#{i}.jpg",'w')
    #   fh.write(p)
    #   fh.close
    #   tmp << "/foto/#{self.id}-#{i}.jpg"
    # end
    # tmp
    @data[:images]
  end

  private

  def report_logger
    @@report_logger ||= Logger.new("#{Rails.root}/log/mdc_report.log")
  end
end

class VacationRequest

  #array of dataCollectionRows
  def initialize(dataCollectionRows, mdc)

    @dataCollectionRows = dataCollectionRows
    @mdc = mdc
    @data = Hash.new
    @dataCollectionRows.each do |dcr|

      next if dcr.applicationID != 'FERIE'
      @type = 0


      @date = Date.strptime(dcr.data[:date], '%Y%m%d')
      @dataCollectionRowKey = dcr.dataCollectionRowKey
      begin
        case dcr.data[:fieldCode]
        when 'date_from' then @data[:date_from] = Date.strptime(dcr.data[:extendedValue].tr('.','/'), '%d/%m/%Y')
          when 'date_to' then @data[:date_to] = Date.strptime(dcr.data[:extendedValue].tr('.','/'), '%d/%m/%Y')
          # when 'time_from' then @data[:time_from] = Date.strptime(dcr.data[:extendedValue], '%h:%M:%s')
          # when 'time_to' then @data[:time_to] = Date.strptime(dcr.data[:extendedValue], '%h:%M:%s')
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
      if dcr.data[:formCode] == 'pdf_report' and dcr.dataCollectionRowKey.progressiveNo == 2
         # @data[:form] = mdc.download_file(dcr.data[:description]).body[/%PDF.*?%%EOF/m].force_encoding("utf-8")
         b = mdc.download_file(dcr.data[:description]).body
         @data[:form] = b[/%PDF.*?%%EOF/m]
        #  b = mdc.download_file(dcr.data[:description]).body
         # @data[:form] = b[/apache\.org>\r\n\r\n(.*)\n\r\n/m,1].force_encoding("utf-8")
         special_logger.info(dcr.data[:description]+"\n"+b+"\n\n")
      end

    end

    @data = nil if @data[:date_from].nil? or @data[:date_to].nil?
    mdc.update_data_collection_rows_status(dataCollectionRows) unless @data.nil?
  end

  def dataCollectionRows
    @dataCollectionRows
  end

  def update_status
    @mdc.update_data_collection_rows_status(@dataCollectionRows,status = 1)
  end

  def reset_status
    @mdc.update_data_collection_rows_status(@dataCollectionRows,status = 0)
  end

  def send_mail
    begin
      HumanResourcesMailer.vacation_request(self).deliver_now
      puts
      puts'Mail sent.'
      puts
    rescue EOFError,
            IOError,
            Errno::ECONNRESET,
            Errno::ECONNABORTED,
            Errno::EPIPE,
            Errno::ETIMEDOUT,
            Net::SMTPAuthenticationError,
            Net::SMTPServerBusy,
            Net::SMTPSyntaxError,
            Net::SMTPUnknownError,
            OpenSSL::SSL::SSLError => e
      puts
      puts 'An error occurred sending mail..'
      puts  e.inspect
      puts
      self.reset_status
    end
    # HumanResourcesMailer.new.vacation_request(self).deliver_now
  end

  def text
    "Richiesta #{self.type}\n\nIl #{self.date}, #{self.person.complete_name} ha richiesto #{self.type} #{self.when}.\n\nQuesta è una mail automatica interna. Non rispondere direttamente a questo indirizzo.\nIn caso di problemi scrivere a ufficioit@chiarcosso.com o contattare direttamente l'amministratore di sistema."
    # render 'human_resources_mailer/vacation_request'
  end

  def filename
    "#{self.date('%Y%m%d')} #{person.complete_name}.pdf"
  end

  def form
    @data[:form]
  end

  def type
    'ferie'
  end

  def data
    @data
  end

  def person
    Person.find_by_mdc_user(@dataCollectionRowKey.deviceCode)
  end

  def date(format = '%d/%m/%Y')
    if format == 'raw'
      @date
    else
      @date.strftime(format)
    end
  end

  def when
    "dal #{self.from} al #{self.to}"
  end

  def from
    case @type
    when 0 then @data[:date_from].strftime("%d/%m/%Y")
    when 1 then @data[:time_from].strftime("%H:%m:%s")
    end
  end

  def to
    case @type
    when 0 then @data[:date_to].strftime("%d/%m/%Y")
    when 1 then @data[:time_to].strftime("%H:%m:%s")
    end
  end

  private

  def special_logger
    @@special_logger ||= Logger.new("#{Rails.root}/log/mdc_webservice_files.log")
  end
end

class GearRequest

  #array of dataCollectionRows
  def initialize(dataCollectionRows, mdc)

    @mdc = mdc
    @dataCollectionRows = dataCollectionRows
    @data = Hash.new
    @data[:items] = {personal_gear: Array.new, vehicle_gear: Array.new, lights_gear: Array.new, shoe_size: nil, overall_size: nil, pickup_dt: nil, pickup_tm: nil}
    @dataCollectionRows.each do |dcr|

      next if dcr.applicationID != 'GEAR'
      @type = 0


      @date = Date.strptime(dcr.data[:date], '%Y%m%d')
      @dataCollectionRowKey = dcr.dataCollectionRowKey
      case dcr.data[:formCode]
        when 'personal_gear' then @data[:items][:personal_gear] << dcr.data[:recordValue]
        when 'vehicle_gear' then @data[:items][:vehicle_gear] << dcr.data[:recordValue]
        when 'lights_gear' then @data[:items][:lights_gear] << dcr.data[:recordValue]
        when 'shoe_size' then @data[:items][:shoe_size] = dcr.data[:recordValue]
        when 'overall_size' then @data[:items][:overall_size] = dcr.data[:recordValue]
        when 'pickup' then dcr.data[:fieldCode] == 'pickup_dt' ? @data[:items][:pickup_dt] = dcr.data[:extendedValue] : @data[:items][:pickup_tm] = dcr.data[:extendedValue]
        # when 'pickup_tm' then @data[:items][:pickup_tm] = dcr.data[:recordValue]
      end
      if dcr.data[:formCode] == 'pdf_report' and dcr.dataCollectionRowKey.progressiveNo == 2
         @data[:form] = mdc.download_file(dcr.data[:description]).body[/%PDF.*?%%EOF/m].force_encoding("utf-8")
      end

    end

    @data = nil if @data.empty?
    mdc.update_data_collection_rows_status(dataCollectionRows) unless @data.nil?
  end

  def dataCollectionRows
    @dataCollectionRows
  end

  def update_status
    @mdc.update_data_collection_rows_status(@dataCollectionRows,status = 1)
  end

  def reset_status
    @mdc.update_data_collection_rows_status(@dataCollectionRows,status = 0)
  end

  def send_mail
    begin
      StorageMailer.gear_request(self,:hr).deliver_now if self.gear_type? :hr
      StorageMailer.gear_request(self,:storage).deliver_now if self.gear_type? :storage
      puts
      puts'Mail sent.'
      puts
    rescue EOFError,
            IOError,
            Errno::ECONNRESET,
            Errno::ECONNABORTED,
            Errno::EPIPE,
            Errno::ETIMEDOUT,
            Net::SMTPAuthenticationError,
            Net::SMTPServerBusy,
            Net::SMTPSyntaxError,
            Net::SMTPUnknownError,
            OpenSSL::SSL::SSLError => e
      puts
      puts 'An error occurred sending mail..'
      puts  e.inspect
      puts
      self.reset_status
    end
    # StorageMailer.new.gear_request(self)
  end

  def gear_type? type
    case type
    when :hr
      !@data[:items][:personal_gear].empty?
    when :storage
      !(@data[:items][:vehicle_gear].empty? && @data[:items][:lights_gear].empty?)
    end
  end

  def text(type = nil)
    text = "Richiesta dotazione\n\nIl #{self.date}, #{self.person.complete_name} ha richiesto la seguente dotazione:\n\n\n"
    if !@data[:items][:personal_gear].empty? && (type.nil? || type == :hr)
      text += "Dotazione personale:\n\n"
      @data[:items][:personal_gear].each do |i|
        text += "   #{i}\n"
      end
      unless @data[:items][:shoe_size].nil?
        text += "\n   Misura scarpe: #{@data[:items][:shoe_size]}"
      end
      unless @data[:items][:overall_size].nil?
        text += "\n   Taglia tuta: #{@data[:items][:overall_size]}"
      end
      text += "\n\n"
    end
    if !@data[:items][:vehicle_gear].empty? && (type.nil? || type == :storage)
      text += "Dotazione mezzo:\n\n"
      @data[:items][:vehicle_gear].each do |i|
        text += "   #{i}\n"
      end
      text += "\n\n"
    end
    if !@data[:items][:lights_gear].empty? && (type.nil? || type == :storage)
      text += "Lampadine:\n\n"
      @data[:items][:lights_gear].each do |i|
        text += "   #{i}\n"
      end
      text += "\n\n"
    end
    text += "Il ritiro è previsto il #{@data[:items][:pickup_dt]} alle #{@data[:items][:pickup_tm]} circa.\n\n"
    text += "\n\nQuesta è una mail automatica interna. Non rispondere direttamente a questo indirizzo.\nIn caso di problemi scrivere a ufficioit@chiarcosso.com o contattare direttamente l'amministratore di sistema."
    # render 'human_resources_mailer/vacation_request'
  end

  def filename
    "#{self.date('%Y%m%d')} #{person.complete_name}.pdf"
  end

  def form
    @data[:form]
  end

  def data
    @data
  end

  def person
    Person.find_by_mdc_user(@dataCollectionRowKey.deviceCode)
  end

  def date(format = '%d/%m/%Y')
    if format == 'raw'
      @date
    else
      @date.strftime(format)
    end
  end


end
