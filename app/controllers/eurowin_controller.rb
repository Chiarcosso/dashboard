class EurowinController < ApplicationController

  def self.get_notification(protocol)
    ewc = get_ew_client
    r = ewc.query("select *, "\
    "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
    "from autosegnalazioni where Protocollo = #{protocol};")
    ewc.close
    r.first
  end

  def self.get_notifications_from_odl(protocol)
    odl = EurowinController::get_worksheet(protocol)
    unless odl.nil?
      ewc = get_ew_client
      r = ewc.query("select *, "\
      "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autosegnalazioni where serialODL = #{odl['Serial']};")
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

  def self.get_worksheet(protocol)
    protocol = protocol[/\d*/]
    ewc = get_ew_client
    r = ewc.query("select * from autoodl where protocollo = #{protocol} limit 1;").first
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
    payload['DataIntervento'] = "null" if payload['DataIntervento'].nil?
    payload['CodiceOfficina'] = "0" if payload['CodiceOfficina'].nil?
    payload['CodiceAutomezzo'] = "0" if payload['CodiceAutomezzo'].nil?
    # payload['UserInsert'] = current_user.person.complete_name.upcase if payload['UserInsert'].nil?
    # payload['DataPost'] = "0" if payload['DataPost'].nil?
    # payload['UserPost'] = "0" if payload['UserPost'].nil?
    # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # payload['FlagStampato'] = "0"
    # payload['TipoDanno'] = "0" if payload['TipoDanno'].nil?
    # payload['FlagRiparato'] = "0" if payload['FlagRiparato'].nil?
    payload['FlagSvolto'] = "null" if payload['FlagSvolto'].nil?
    payload['FlagJSONType'] = "sgn"

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
    payload['AnnoSGN'] = "0" if payload['AnnoSGN'].nil?
    payload['ProtocolloSGN'] = "0" if payload['ProtocolloSGN'].nil?
    payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
    payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    payload['TipoDanno'] = '55' if payload['TipoDanno'].nil?
    payload['FlagSvolto'] = "false" if payload['FlagSvolto'].nil?
    payload['FlagJSONType'] = "odl"

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
    mssql = vehicle.mssql_references.first
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

  private

  def self.get_ew_client(db = ENV['RAILS_EUROS_DB'])
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: db
  end

  def self.special_logger
    @@ew_logger ||= Logger.new("#{Rails.root}/log/eurowin_ws.log")
  end
end
