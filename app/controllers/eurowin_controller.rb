class EurowinController < ApplicationController

  def self.get_notifications_from_odl(protocol)
    odl = EurowinController::get_worksheet(protocol)
    ewc = get_ew_client
    r = ewc.query("select * from autosegnalazioni where serialODL = #{odl['Serial']};")
    ewc.close
    r
  end

  def self.get_operator_from_odl(protocol)
    odl = EurowinController::get_worksheet(protocol)
    ewc = get_ew_client
    r = ewc.query("select CodiceManutentore from autoodl where Serial = #{odl['Serial']};")
    ewc.close
    ewc = get_ew_client('common')
    op = ewc.query("select * from operatori where Codice = '#{r.first['CodiceManutentore']}';")
    ewc.close
    op.first
  end

  def self.get_worksheet(protocol)
    protocol = protocol[/\d*/]
    ewc = get_ew_client
    r = ewc.query("select * from autoodl where protocollo = #{protocol} limit 1;").first
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
    payload['DataInsert'] = Date.current.strftime('%Y-%m-%d') if payload['DataInsert'].nil?
    # payload['UserInsert'] = current_user.person.complete_name.upcase if payload['UserInsert'].nil?
    payload['DataPost'] = Date.current.strftime('%Y-%m-%d') if payload['DataPost'].nil?
    payload['UserPost'] = 'Sconosciuto' if payload['UserPost'].nil?
    payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    payload['FlagStampato'] = 'false'
    payload['TipoDanno'] = '55' if payload['TipoDanno'].nil?
    payload['FlagRiparato'] = "false" if payload['FlagRiparato'].nil?
    payload['FlagSvolto'] = "false" if payload['FlagSvolto'].nil?
    payload['FlagJSONType'] = "sgn"

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    VehiclePerformedCheck.special_logger.info(request)
    res = JSON.parse(HTTPI.post(request).raw_body)['ProtocolloSGN']

    c = get_ew_client
    sgn = c.query("select * from autosegnalazioni where protocollo = #{res}")
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
    VehiclePerformedCheck.special_logger.info(request)
    res = JSON.parse(HTTPI.post(request).raw_body)['ProtocolloSGN']

    c = get_ew_client
    sgn = c.query("select * from autosegnalazioni where protocollo = #{res}")
    c.close

    return sgn.first unless sgn.count < 1

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
end
