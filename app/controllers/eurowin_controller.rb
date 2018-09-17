class EurowinController < ApplicationController

  def self.get_notification(protocol)
    ewc = get_ew_client
    r = ewc.query("select *, "\
    "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
    "from autosegnalazioni where Protocollo = #{protocol};")
    ewc.close
    r.first
  end

  def self.get_notifications_from_odl(protocol,mod = :opened)
    odl = EurowinController::get_worksheet(protocol)
    case mod
    when :all then
      w = ""
    when :opened then
      w = " and ((FlagRiparato like 'false' and FlagChiuso like 'false') "\
          "or (FlagChiuso is null and FlagRiparato is null) "\
          "or (FlagRiparato like 'false' and FlagChiuso is null) "\
          "or (FlagRiparato is null and FlagChiuso like 'false'))"
    when :closed then
      w = " and FlagRiparato like 'true' and FlagChiuso like 'true' "
    end
    unless odl.nil?
      ewc = get_ew_client
      r = ewc.query("select *, "\
      "(select RagioneSociale from anagrafe where codice = CodiceAutista) as NomeAutista, "\
      "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autosegnalazioni where serialODL = #{odl['Serial']}#{w};")
      ewc.close
      r
    end
  end

  def self.get_operator_from_odl(protocol)
    odl = EurowinController::get_worksheet(protocol)
    unless odl.nil?
      ewc = get_ew_client
      r = ewc.query("select CodiceManutentore from autoodl where Serial = #{odl['Serial']};")
      ewc.close
      ewc = get_ew_client('common')
      op = ewc.query("select * from operatori where Codice = '#{r.first['CodiceManutentore']}';")
      ewc.close
      op.first
    end
  end

  def self.get_operators(search)
    ewc = get_ew_client('common')
    op = ewc.query("select * from operatori where Descrizione like #{ActiveRecord::Base::sanitize("%#{search}%")};")
    ewc.close
    op
  end

  def self.get_worksheets(opts)

    #set deafults
    opts[:opened] = :opened if opts[:opened].nil?
    opts[:search] = nil if opts[:search].nil?
    opts[:station] = :workshop if opts[:station].nil?

    #build where conditions
    case opts[:opened]
    when :all then
      w = "1 = 1"
    when :opened then
      w = "lower(FlagSchedaChiusa) = 'false'"
    when :closed then
      w = "lower(FlagSchedaChiusa) = 'true'"
    else
      w = "1 = -1"
    end

    wstation = " and CodiceAnagrafico = '#{get_workshop(opts[:station])}'" unless opts[:station].nil?

    unless opts[:search].nil?
      ops = EurowinController::get_operators(opts[:search])
      if ops.count > 0
        wops = " or codicemanutentore in (#{ops.map{ |o| "'#{o['Codice']}'" }.join(',')}))"
      else
        wops = ")"
      end
      w += " and (targa like #{ActiveRecord::Base::sanitize("%#{opts[:search]}%")} "\
      "or protocollo like #{ActiveRecord::Base::sanitize("%#{opts[:search]}%")}#{wops}"
    end
    #send query
    q = "select * from autoodl where #{w}#{wstation};"

    ewc = get_ew_client
    r = ewc.query(q)
    ewc.close
    r
  end

  def self.get_worksheet(protocol)
    protocol = protocol.to_s[/\d*/]
    ewc = get_ew_client
    r = ewc.query("select * from autoodl where CodiceAutomezzo is not null and protocollo = #{protocol} limit 1;").first
    ewc.close

    r
  end

  def self.last_maintainance(vehicle)
    ewc = get_ew_client
    query = "select * from autoodl "\
    "where codiceautomezzo in (#{vehicle.mssql_references.map{|mr| mr.remote_object_id}.join(',')}) "\
    "and (CodiceTipoDanno = '#{get_tipo_danno('MANUTENZIONE')}' or CodiceTipoDanno = '#{get_tipo_danno('COLLAUDO')}') "\
    "and FlagSchedaChiusa like 'true' "\
    "order by DataUscitaVeicolo desc limit 1"
    r = ewc.query(query).first
    ewc.close

    r
  end

  def self.last_open_odl_not(protocol)
    odl = get_worksheet(protocol)

    ewc = get_ew_client
    r = ewc.query("select * from autoodl where protocollo = "\
    "(select protocollo from autoodl where codiceautomezzo = '#{odl['CodiceAutomezzo']}' and protocollo != #{odl['Protocollo']} "\
    "and DataUscitaVeicolo is null and FlagSchedaChiusa like 'false' "\
    "and CodiceAnagrafico = '#{get_workshop(:workshop)}' "\
    "order by dataintervento desc limit 1)").first
    ewc.close

    r
  end

  def self.create_notification(payload)

    payload = payload.stringify_keys

    payload['AnnoODL'] = "-1" if payload['AnnoODL'].nil?
    payload['ProtocolloODL'] = "-1" if payload['ProtocolloODL'].nil?
    payload['AnnoSGN'] = "0" if payload['AnnoSGN'].nil?
    payload['ProtocolloSGN'] = "0" if payload['ProtocolloSGN'].nil?
    payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
    payload['CodiceOfficina'] = "0" if payload['CodiceOfficina'].nil?
    payload['CodiceAutomezzo'] = "0" if payload['CodiceAutomezzo'].nil?
    payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?
    payload['CodiceAutista'] = payload['CodiceAutista'].rjust(6,'0') unless payload['CodiceAutista'].nil?
    payload['UserInsert'] = payload['CodiceAutista'].gsub("'","\\'") unless payload['UserInsert'].nil?
    # payload['DataPost'] = "0" if payload['DataPost'].nil?
    # payload['UserPost'] = "0" if payload['UserPost'].nil?
    # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # payload['FlagStampato'] = "0"
    # payload['TipoDanno'] = "0" if payload['TipoDanno'].nil?
    # payload['FlagRiparato'] = "0" if payload['FlagRiparato'].nil?
    payload['FlagRiparato'] = "null" if payload['FlagRiparato'].nil?
    payload['FlagStampato'] = "null" if payload['FlagStampato'].nil?
    payload['FlagSvolto'] = "null" if payload['FlagSvolto'].nil?
    payload['FlagJSONType'] = "sgn"

    payload.each { |k,v| payload.delete(k) if v.nil? }

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'

    special_logger.info(request)
    response = HTTPI.post(request)
    special_logger.info(response)
    res = JSON.parse(response.raw_body)['ProtocolloSGN']

    c = get_ew_client
    sgn = c.query("select * from autosegnalazioni where protocollo = '#{res}'")
    c.close

    return sgn.first unless sgn.count < 1

  end

  def self.create_worksheet(payload)

    payload = payload.stringify_keys

    payload['AnnoODL'] = "0" if payload['AnnoODL'].nil?
    payload['ProtocolloODL'] = "0" if payload['ProtocolloODL'].nil?
    payload['AnnoSGN'] = "-1" if payload['AnnoSGN'].nil?
    payload['ProtocolloSGN'] = "-1" if payload['ProtocolloSGN'].nil?
    payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
    payload['CodiceOfficina'] = "0" if payload['CodiceOfficina'].nil?
    payload['CodiceAutomezzo'] = "0" if payload['CodiceAutomezzo'].nil?
    payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?

    # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # payload['TipoDanno'] = '55' if payload['TipoDanno'].nil?
    payload['FlagSvolto'] = "null" if payload['FlagSvolto'].nil?
    payload['FlagJSONType'] = "odl"

    payload.each { |k,v| payload.delete(k) if v.nil? }
    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    special_logger.info(request)
    response = HTTPI.post(request)
    special_logger.info(response)

    res = JSON.parse(response.raw_body)['ProtocolloODL']

    c = get_ew_client
    odl = c.query("select * from autoodl where protocollo = #{res}")
    c.close

    return odl.first unless odl.count < 1

  end

  def self.get_workshop(station)
    case station
    when :workshop then
      station_code = 'OFFICINA INTERNA'
    when :carwash
      station_code = 'PUNTO CHECK-UP'
    end
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    workshop = ewc.query("select codice from anagrafe where ragioneSociale = '#{station_code}'")
    ewc.close
    return workshop.first['codice'] unless workshop.count < 1
  end

  def self.get_vehicle(vehicle)
    vehicle_refs = { 'CodiceAutomezzo': nil, 'CodiceAutista': nil, 'Targa': nil, 'Km': nil }
    mssql = vehicle.mssql_references.last
    vehicle_refs['CodiceAutomezzo'] = mssql.remote_object_id.to_s

    case mssql.remote_object_table
    when 'Veicoli' then
      field = 'idveicolo'
    when 'Rimorchi1' then
      field = 'idrimorchio'
    when 'Altri Mezzi' then
      field = 'COD'
    end

    opcode = VehiclePerformedCheck.get_ms_client.execute("select nominativo from autisti where idautista = "+vehicle.last_driver.mssql_references.last.remote_object_id.to_s).first['nominativo'] unless vehicle.last_driver.nil?
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    vehicle_refs['CodiceAutista'] = ewc.query("select codice from autisti where ragionesociale = '#{opcode}'").first
    ewc.close
    vehicle_refs['CodiceAutista'] = vehicle_refs['CodiceAutista']['codice'] unless vehicle_refs['CodiceAutista'].nil?

    vehicle_refs['Targa'] = vehicle.plate
    vehicle_refs['Km'] = vehicle.mileage
    return vehicle_refs
  end

  def self.get_tipi_danno
    query = "select * from tabdesc where gruppo = 'AUTOTIPD' order by Descrizione"
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    dt = ewc.query(query)
    ewc.close
    return dt
  end

  def self.get_odl_tipo_danno(odl, whole = false)

    query = "select * from tabdesc where gruppo = 'AUTOTIPD' and Codice = (select CodiceTipoDanno from autoodl where protocollo = #{odl.number})"
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    dt = ewc.query(query)
    ewc.close

    if whole
      return dt.first
    else
      return dt.first['Codice'] unless dt.count < 1
    end
  end

  def self.get_tipo_danno(tipodanno, whole = false)

    if tipodanno.to_i > 0
      query = "select * from tabdesc where codice = #{tipodanno.gsub("'","''")} and gruppo = 'AUTOTIPD'"
    else
      query = "select * from tabdesc where gruppo = 'AUTOTIPD' and Descrizione = '#{tipodanno.gsub("'","''")}'"
    end
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    dt = ewc.query(query)
    ewc.close
    if whole
      return dt.first
    else
      return dt.first['Codice'] unless dt.count < 1
    end
  end

  private

  def self.get_ew_client(db = ENV['RAILS_EUROS_DB'])
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: db
  end

  def self.special_logger
    @@ew_logger ||= Logger.new("#{Rails.root}/log/eurowin_ws.log")
  end
end
