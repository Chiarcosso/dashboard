class EurowinController < ApplicationController
  include AppHelper

  def self.get_notification(protocol)
    ewc = get_ew_client
    r = ewc.query("select *, "\
    "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
    "from autosegnalazioni where Protocollo = #{protocol};")
    ewc.close
    r.first
  end

  def self.get_open_notifications_complete(vehicle,except,unprinted = false)
    mrs = vehicle.mssql_references.map{ |msr| msr.remote_object_id }
    printed = "and FlagStampato not like 'true'" if unprinted

    if mrs.empty?
      Array.new
    else
      ewc = get_ew_client
      q = "select *, "\
      "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autosegnalazioni where DataSegnalazione is not null and DataSegnalazione <> '0000-00-00' and codiceAutomezzo in (#{mrs.join(',')}) "\
      "#{printed} and FlagChiuso not like 'true' and FlagRiparato not like 'true' "\
      "and (serialODL is null or serialODL not in (select serial from autoodl where protocollo = #{except}));"
      r = ewc.query(q)
      ewc.close
      r
    end
  end

  def self.get_open_notifications(search,unprinted = false)

    plate_id = VehicleInformationType.find_by(name: 'Targa').id
    printed = "FlagStampato not like 'true' and" if unprinted
    plates = Array.new
    wherev = Array.new
    wherex = Array.new
    unless search[:odl].nil? || search[:odl].empty?
      plates = search[:odl].map{ |o| "'#{o[:plate].to_s.gsub("'","''").gsub(';','')}'"}
      wherev << "vehicle_information_type_id = #{plate_id} and information in (#{plates.join(',')})"
      wherex << "plate in (#{plates.join(',')})"
    end
    unless search[:plate].to_s == ''
      wherev << "information like '%#{search[:plate].to_s.gsub("'","''").gsub(';','')}%'"
      wherex << "plate like '%#{search[:plate].to_s.gsub("'","''").gsub(';','')}%'"
    end

    if wherev.empty?
      mrs = Array.new
    else
      mrs = Array.new
      q = <<-QUERY
        select * from mssql_references
        where (local_object_type = 'Vehicle' or local_object_type = 'ExternalVehicle')
        and local_object_id in (
          select distinct sq.id from (
            select vehicle_id as id from vehicle_informations where vehicle_information_type_id = #{plate_id} and (#{wherev.join(' or ')})

            union
            select id from external_vehicles where #{wherex.join(' or ')}
          ) sq
        )
      QUERY
      mrs = MssqlReference.find_by_sql(q)
    end
    ewc = get_ew_client
    if mrs.empty?
      query = "select *, "\
      "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autosegnalazioni where "\
      "#{printed} (serialODL is null or serialODL = 0) and DataSegnalazione is not null and DataSegnalazione <> '0000-00-00' and FlagChiuso not like 'true' and FlagRiparato not like 'true';"
    else

      query = "select *, "\
      "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autosegnalazioni where codiceAutomezzo in (#{mrs.map{|mr| mr.remote_object_id}.join(',')}) "\
      "and #{printed} (serialODL is null or serialODL = 0) and DataSegnalazione is not null and DataSegnalazione <> '0000-00-00' and FlagChiuso not like 'true' and FlagRiparato not like 'true';"

    end
    r = ewc.query(query)
    ewc.close

    r
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
      query = "select *, "\
      "(select RagioneSociale from anagrafe where codice = CodiceAutista) as NomeAutista, "\
      "(select descrizione from tabdesc where codice = tipodanno and gruppo = 'AUTOTIPD') as TipoDanno "\
      "from autosegnalazioni where DataSegnalazione is not null and DataSegnalazione <> '0000-00-00' and serialODL = #{odl['Serial']}#{w};"
      ewc = get_ew_client
      r = ewc.query(query)

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

  def self.get_worksheets_complete(vehicle)
    return [] if vehicle.mssql_references.empty?
    ewc = get_ew_client
    vehicles = vehicle.mssql_references.map { |v| "'#{v.remote_object_id}'" }
    op = ewc.query(
    <<-QUERY
      select autoodl.*,
      (select RagioneSociale from anagrafe where anagrafe.codice = autoodl.CodiceAnagrafico) as NomeOfficina
      from autoodl
      where autoodl.codiceAutomezzo in (#{vehicles.join(',')})
      order by DataEntrataVeicolo desc
    QUERY
    )
    ewc.close
    op
  end

  def self.get_operators(search)
    ewc = get_ew_client('common')
    op = ewc.query("select * from operatori where Descrizione like #{ActiveRecord::Base::sanitize("%#{search}%")};")
    ewc.close
    op
  end

  def self.closed_worksheets
    get_worksheets(:opened => :closed)
  end

  def self.reset_odl(protocol)
    ewc = get_ew_client
    r = ewc.query("update autoodl set dataentrataveicolo = null where protocollo = #{protocol}")
    ewc.close

    r
  end

  def self.get_last_open_odl_by_vehicle(vehicle)
    ewc = get_ew_client
    r = ewc.query("select * from autoodl "\
    "where codiceautomezzo = '#{vehicle}' "\
    "and DataUscitaVeicolo is null "\
    "and FlagSchedaChiusa not like 'true' "\
    "and CodiceAnagrafico = '#{get_workshop(:workshop)}' "\
    "order by dataintervento desc limit 1").first
    ewc.close

    r
  end


  def self.get_worksheets(opts)

    #set deafults
    opts[:opened] = :opened if opts[:opened].nil?
    opts[:search_fields] = [:plate,:operator,:protocol] if opts[:search_fields].nil?
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

      ops = EurowinController::get_operators(opts[:search][:search_operator])
      if ops.count > 0 && !opts[:search][:search_operator].nil?
        wops = " and codicemanutentore in (#{ops.map{ |o| "'#{o['Codice']}'" }.join(',')}) "
      else
        wops = ""
      end

      # w += " and (targa like #{ActiveRecord::Base::sanitize("%#{opts[:search]}%")} "\
      w += " and convert(protocollo,char) like #{ActiveRecord::Base::sanitize("%#{opts[:search][:number]}%")}"
      plate = opts[:search][:plate].split('').join('%') unless opts[:search][:plate].nil?
      w += " and targa like #{ActiveRecord::Base::sanitize("%#{plate}%")}#{wops}"\
    end
    #send query
    q = "select * from autoodl where #{w}#{wstation} order by targa;"

    ewc = get_ew_client
    r = ewc.query(q)
    ewc.close
    r
  end

  def self.get_worksheet(protocol)

    begin
      if protocol.to_s == ''
        nil
      else
        protocol = protocol.to_s[/\d*/]
        ewc = get_ew_client
        r = ewc.query("select * from autoodl where CodiceAutomezzo is not null and protocollo = #{protocol} limit 1;").first
        ewc.close

        r
      end

    rescue Exception => e
      puts "#{e.message}\n\n#{e.backtrace.join("\n")}"
      ErrorMailer.error_report("#{e.message}\n\n#{e.backtrace.join("\n")}","Eurowin get_worksheet, protocol: #{protocol}").deliver_now
    end
  end

  def self.get_odl_from_notification(notification)
    if notification.class == Fixnum || notification.class == String
      protocol = notification.to_s[/\d*/]
    else
      protocol = notification['Protocollo']
    end
    ewc = get_ew_client
    r = ewc.query("select * from autoodl where CodiceAutomezzo is not null and protocollo = (select SchedaInterventoProtocollo from autosegnalazioni where Protocollo = #{protocol}) limit 1;").first
    ewc.close

    r
  end

  def self.last_maintainance(vehicle)
    ewc = get_ew_client
    if vehicle.mssql_references.empty?
      vehicle.update_references
    end
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
    "and DataUscitaVeicolo is null and FlagSchedaChiusa not like 'true' "\
    "and CodiceAnagrafico = '#{get_workshop(:workshop)}' "\
    "order by dataintervento desc limit 1)").first
    ewc.close

    r
  end

  def self.create_ew_notification(args)
    ew_query_logger.info("#{@token} (new create notification request) => #{args.inspect}")
    args.each { |k,v| args.delete(k) if v.nil? }
    puts args.inspect
    if args[:datasegnalazione].nil?
      args[:datasegnalazione] = DateTime.now
    end
    if args[:schedainterventoprotocollo].nil? || args[:schedainterventoprotocollo] == 0 || args[:schedainterventoprotocollo] == "0"
      args.delete(:schedainterventoprotocollo)
    end

    if args[:schedainterventoanno].nil? || args[:schedainterventoanno] == 0 || args[:schedainterventoanno] == "0"
      args.delete(:schedainterventoanno)
    end

    # qry = "select Protocollo from autosegnalazioni order by Protocollo desc limit 1;"
    # res = c.query(qry).first
    # protocollo = res['Protocollo']
    # unless args['']
    #
    # end
    fields = []
    values = []
    args.each do |k,v|
      # args[k] = 'null' if v.nil?
      args[k] = v.strftime('%Y-%m-%d') if v.is_a?(Date) || v.is_a?(DateTime)
      args[k] = "'#{args[k].gsub("'","''").gsub(';','.').gsub("\\","\\\\")[0..195]}'" if args[k].is_a?(String) && args[k] != 'null'
    end
    args.each do |field,value|
      fields << field
      # if value.is_a? String
      #   value = "'#{value}'"
      # end
      # value = value.strftime('%Y-%m-%d') if value.is_a?(Date) || value.is_a?(DateTime)
      # value = value.is_a?(String) && !value.nil? ? "'#{value.gsub("'","")}'" : value
      values << value
    end

    unless args[:schedainterventoprotocollo].nil?
      fields << 'SerialODL'
      values << "(select serial from autoodl where protocollo = #{args[:schedainterventoprotocollo]})"
    end
    unless args[:codiceautomezzo].nil?
      fields << 'targa'
      values << "(select targa from automezzi where codice = #{args[:codiceautomezzo]})"
    end
    anno = args[:datasegnalazione].match(/^'?([0-9]{4})-.*/)[1]

    # qry = "set @nextprotocol = (select max(protocollo)+1 from autosegnalazioni);\n"
    # qry += "insert into autosegnalazioni (Anno,Protocollo,Sezione,#{fields.join(',')}) values (#{anno},@nextprotocol,'A',#{values.join(',')});\n"
    # qry += "select * from autosegnalazioni where protocollo = @nextprotocol"
    qry = [
      "set @nextprotocol = (select max(protocollo)+1 from autosegnalazioni);",
      "insert into autosegnalazioni (Anno,Protocollo,Sezione,#{fields.join(',')}) values (#{anno},@nextprotocol,'A',#{values.join(',')});",
      "select * from autosegnalazioni where protocollo = @nextprotocol;"
    ]

    # c = get_ew_client
    # c.query(qry)
    ew_query_logger.info("#{@token} (new create notification query) => #{qry.inspect}")
    multi_query(qry)
    # prot =  c.query("select @nextprotocol")
    # sgn = c.async_result

    # c.close

    qry = "select * from autosegnalazioni where #{args.map{|f,v| "#{f} = #{v}"}.join(' and ')} order by Protocollo desc limit 1"
    ew_query_logger.info("#{@token} (find new notification query) => #{qry.inspect}")

    c = get_ew_client
    sgn = c.query(qry)

    c.close
    if sgn.first.nil?
      sleep 1
      c = get_ew_client
      sgn = c.query(qry)
      # sgn = c.query("select * from autosegnalazioni where protocollo = #{prot};")
      c.close
    end

    ew_query_logger.info("#{@token} (new create notification result) => #{qry}\n#{sgn.nil? ? 'SQL error' : sgn.first.inspect}")
    return sgn.first
  end

  def self.edit_ew_notification(args)
    ew_query_logger.info("#{@token} (new edit notification request) => #{args.inspect}")
    puts args.inspect

    args.each do |k,v|
      args[k] = 'null' if v.nil?
      args[k] = v.strftime('%Y-%m-%d') if v.is_a?(Date) || v.is_a?(DateTime)
      args[k] = "'#{args[k].gsub("'","''").gsub(';','.').gsub("\\","\\\\")[0..195]}'" if args[k].is_a?(String) && args[k] != 'null'
    end

    if args[:schedainterventoprotocollo].nil? || args[:schedainterventoprotocollo] == 0 || args[:schedainterventoprotocollo] == "0"
      args.delete(:schedainterventoprotocollo)
    end

    if args[:schedainterventoanno].nil? || args[:schedainterventoanno] == 0 || args[:schedainterventoanno] == "0"
      args.delete(:schedainterventoanno)
    end

    updates = Array.new
    args.each do |field,value|
      updates << "#{field} = #{value}"
    end

    unless args[:schedainterventoprotocollo].nil?
      updates << "SerialODL = (select serial from autoodl where protocollo = #{args[:schedainterventoprotocollo]})"
    end

    qry = [
      "update autosegnalazioni set #{updates.join(', ')} where protocollo = #{args[:protocollo]} ;",
      "select * from autosegnalazioni where protocollo = #{args[:protocollo]};"
    ]
    # c = get_ew_client
    # sgn = c.query(qry)
    # prot =  c.query("select @nextprotocol")
    # sgn = c.async_result
    ew_query_logger.info("#{@token} (new edit notification query) => #{qry.inspect}")
    multi_query(qry)
    # c.close

    qry = "select * from autosegnalazioni where protocollo = #{args[:protocollo]};"
    c = get_ew_client
    sgn = c.query(qry)
    # sgn = c.query("select * from autosegnalazioni where protocollo = #{prot};")
    #
    # c.close
    ew_query_logger.info("#{@token} (new edit notification result) => #{sgn.nil? ? 'null' : sgn.first.inspect}")

    return sgn.first
  end

  def self.create_notification(payload)
    @token = SecureRandom.hex
    ew_query_logger.info("#{@token} (old notification method request) => #{payload.inspect}")

    ## '0' means new one
    ## '-1' means don't change
    ## 'null' means write null
    payload = payload.stringify_keys

    payload['AnnoODL'] = nil if payload['AnnoODL'] == '-1'
    if payload['AnnoODL'] == '0'
      payload.delete('AnnoODL')
    end
    if payload['ProtocolloODL'] == '0'
      payload.delete('ProtocolloODL')
    end
    payload['ProtocolloODL'] = nil if payload['ProtocolloODL'] == '-1'

    payload['AnnoSGN'] = nil if payload['AnnoSGN'] == '0'
    payload['ProtocolloSGN'] = nil if payload['ProtocolloSGN'] == '0'

    payload['CodiceOfficina'] = nil if payload['CodiceOfficina'] == '0'
    payload['CodiceAutomezzo'] = nil if payload['CodiceAutomezzo'] == '0'

    payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?
    payload['CodiceAutista'] = payload['CodiceAutista'].rjust(6,'0') unless payload['CodiceAutista'].nil?
    payload['UserInsert'] = payload['UserInsert'].to_s.gsub("'","\\'") unless payload['UserInsert'].nil?

    # payload['DataPost'] = "0" if payload['DataPost'].nil?
    # payload['UserPost'] = "0" if payload['UserPost'].nil?
    # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # payload['FlagStampato'] = false
    # payload['TipoDanno'] = "0" if payload['TipoDanno'].nil?
    # payload['FlagRiparato'] = "0" if payload['FlagRiparato'].nil?
    payload['FlagRiparato'] = nil if payload['FlagRiparato'] == 'null'
    payload['FlagStampato'] = nil if payload['FlagStampato'] == 'null'
    payload['FlagSvolto'] = nil if payload['FlagSvolto'] == 'null'

    if payload['ProtocolloSGN'].nil?

      payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
      payload['OraIntervento'] = Time.now.strftime('%H:%M:%S') if payload['OraIntervento'].nil?

      unless payload['CodiceAutomezzo'].nil?
        c = get_ew_client
        qry = "select codiceProvenienza from automezzi where codice = '#{payload['CodiceAutomezzo']}'"
        am = c.query(qry).first['codiceProvenienza'].split(' ')
        c.close

        vehicle = Vehicle.find_by_reference(am[0],am[1])

        lm = last_maintainance(vehicle)
        lc = vehicle.last_check
        payload['DataUltimaManutenzione'] = lm['DataUscitaVeicolo'].strftime("%Y-%m-%d") unless lm.nil?
        payload['DataUltimoControllo'] = lc.time.strftime("%Y-%m-%d") unless lc.nil?
      end

      payload['DataInsert'] = Date.today.strftime("%Y-%m-%d") if payload['DataInsert'].nil?

      payload['FlagRiparato'] = 'false' if payload['FlagRiparato'].nil?
      payload['FlagStampato'] = 'false' if payload['FlagStampato'].nil?
      payload['FlagSvolto'] = 'false' if payload['FlagSvolto'].nil?

      payload['UserInsert'] = 'DASHBOARD' if payload['UserInsert'].nil?
    end
    # payload.each { |k,v| payload.delete(k) if v.nil? }

    if payload['ProtocolloSGN'].nil?
      return create_ew_notification(
        datasegnalazione: payload['DataIntervento'],
        orasegnalazione: payload['OraIntervento'],
        codiceautista: payload['CodiceAutista'].to_s,
        descrizionesegnalazione: payload['Descrizione'],
        tipodanno: payload['TipoDanno'],
        flagstampato: payload['FlagStampato'].to_s,
        flagchiuso: payload['FlagSvolto'].to_s,
        flagriparato: payload['FlagRiparato'].to_s,
        dataultimamanutenzione: payload['DataUltimaManutenzione'],
        dataultimocontrollo: payload['DataUltimoControlo'],
        km: payload['Chilometraggio'].to_i,
        datainsert: payload['DataInsert'],
        userinsert: payload['UserInsert'][0..19],
        datapost: payload['DataPost'],
        userpost: payload['UserPost'][0..19],
        schedainterventoanno: payload['AnnoODL'].to_i,
        schedainterventoprotocollo: payload['ProtocolloODL'].to_i,
        codiceautomezzo: payload['CodiceAutomezzo'],
        codicefornitore: payload['CodiceOfficina']
      )
    else
      args = Hash.new
      args[:protocollo] = payload['ProtocolloSGN']
      args[:datasegnalazione] = payload['DataIntervento'] if payload.has_key? 'DataIntervento'
      args[:orasegnalazione] = payload['OraIntervento'] if payload.has_key? 'OraIntervento'
      args[:codiceautista] = payload['CodiceAutista'] if payload.has_key? 'CodiceAutista'
      args[:descrizionesegnalazione] = payload['Descrizione'] if payload.has_key? 'Descrizione' && payload['Descrizione'] != ''
      args[:tipodanno] = payload['TipoDanno'] if payload.has_key? 'TipoDanno'
      args[:flagstampato] = payload['FlagStampato'].to_s if payload.has_key? 'FlagStampato'
      args[:flagchiuso] = payload['FlagSvolto'].to_s if payload.has_key? 'FlagSvolto'
      args[:flagriparato] = payload['FlagRiparato'].to_s if payload.has_key? 'FlagRiparato'
      args[:dataultimamanutenzione] = payload['DataUltimaManutenzione'] if payload.has_key? 'DataUltimaManutenzione'
      args[:dataultimocontrollo] = payload['DataUltimoControllo'] if payload.has_key? 'DataUltimoControllo'
      args[:km] = payload['Chilometraggio'].to_i if payload.has_key? 'Chilometraggio'
      args[:datainsert] = payload['DataInsert'] if payload.has_key? 'DataInsert'
      args[:userinsert] = payload['UserInsert'][0..19] if payload.has_key? 'UserInsert'
      args[:datapost] = payload['DataPost'] if payload.has_key? 'DataPost'
      args[:userpost] = payload['UserPost'][0..19] if payload.has_key? 'UserPost'
      args[:schedainterventoanno] = payload['AnnoODL'] if payload.has_key? 'AnnoODL'
      args[:schedainterventoprotocollo] = payload['ProtocolloODL'] if payload.has_key? 'ProtocolloODL'
      args[:codiceautomezzo] = payload['CodiceAutomezzo'] if payload.has_key? 'CodiceAutomezzo'
      args[:codicefornitore] = payload['CodiceOfficina'] if payload.has_key? 'CodiceOfficina'
      return edit_ew_notification(args)
    end
    # payload = payload.stringify_keys
    #
    # payload['AnnoODL'] = "-1" if payload['AnnoODL'].nil?
    # payload['ProtocolloODL'] = "-1" if payload['ProtocolloODL'].nil?
    # payload['AnnoSGN'] = "0" if payload['AnnoSGN'].nil?
    # payload['ProtocolloSGN'] = "0" if payload['ProtocolloSGN'].nil?
    # payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
    # if payload['OraIntervento'].nil?
    #   time = Time.now.strftime('%H:%M:%S')
    # else
    #   time = payload['OraIntervento']
    # end
    # payload['CodiceOfficina'] = "0" if payload['CodiceOfficina'].nil?
    # payload['CodiceAutomezzo'] = "0" if payload['CodiceAutomezzo'].nil?
    # payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    # payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?
    # payload['CodiceAutista'] = payload['CodiceAutista'].rjust(6,'0') unless payload['CodiceAutista'].nil?
    # payload['UserInsert'] = payload['CodiceAutista'].to_s.gsub("'","\\'") unless payload['UserInsert'].nil?
    # # payload['DataPost'] = "0" if payload['DataPost'].nil?
    # # payload['UserPost'] = "0" if payload['UserPost'].nil?
    # # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # # payload['FlagStampato'] = "0"
    # # payload['TipoDanno'] = "0" if payload['TipoDanno'].nil?
    # # payload['FlagRiparato'] = "0" if payload['FlagRiparato'].nil?
    # payload['FlagRiparato'] = "null" if payload['FlagRiparato'].nil?
    # payload['FlagStampato'] = "null" if payload['FlagStampato'].nil?
    # payload['FlagSvolto'] = "null" if payload['FlagSvolto'].nil?
    # payload['FlagJSONType'] = "sgn"
    #
    # payload.each { |k,v| payload.delete(k) if v.nil? }
    #
    # request = HTTPI::Request.new
    # request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    # request.body = payload.to_json
    # request.headers['Content-Type'] = 'application/json; charset=utf-8'
    #
    # special_logger.info(request)
    # response = HTTPI.post(request)
    # special_logger.info(response)
    # res = JSON.parse(response.raw_body)['ProtocolloSGN']
    # year = JSON.parse(response.raw_body)['AnnoSGN']
    #
    #
    # c = get_ew_client
    # qry = "update autosegnalazioni set OraSegnalazione = '#{time}' where protocollo = '#{res}' and anno = #{year}"
    # sgn = c.query(qry)
    #
    # qry = "select * from autosegnalazioni where protocollo = '#{res}'"
    # sgn = c.query(qry)
    # c.close
    #
    # return sgn.first unless sgn.count < 1

  end

  def self.create_ew_worksheet(args)
    ew_query_logger.info("#{@token} (new create worksheet request) => #{args.inspect}")
    args.each { |k,v| args.delete(k) if v.nil? || v == '' }
    puts args.inspect
    if args[:dataintervento].nil?
      args[:dataintervento] = DateTime.now
    end

    unless args[:codiceautista].is_a? String || args[:codiceautista].nil?
      args[:codiceautista] = args[:codiceautista].to_s.rjust(6,'0')
    end
    args.delete(:codiceautista) if args[:codiceautista] == '000000'

    fields = []
    values = []
    args.each do |k,v|
      # args[k] = 'null' if v.nil?
      args[k] = v.strftime('%Y-%m-%d') if v.is_a?(Date) || v.is_a?(DateTime)
      args[k] = "'#{args[k].gsub("'","''").gsub(';','.').gsub("\\","\\\\")[0..195]}'" if args[k].is_a?(String) && args[k] != 'null'
    end
    args.each do |field,value|
      fields << field
      # if value.is_a? String
      #   value = "'#{value}'"
      # end
      # value = value.strftime('%Y-%m-%d') if value.is_a?(Date) || value.is_a?(DateTime)
      # value = value.is_a?(String) && !value.nil? ? "'#{value.gsub("'","")}'" : value
      values << value
    end


    raise "Mezzo mancante." if args[:codiceautomezzo].nil?
    if args[:targa].nil?
      fields << 'targa'
      values << "(select targa from automezzi where codice = #{args[:codiceautomezzo]})"
    end

    c = get_ew_client
    qry = "select codiceProvenienza from automezzi where codice = #{args[:codiceautomezzo]}"
    am = c.query(qry).first['codiceProvenienza'].split(' ')
    c.close
    vehicle = Vehicle.find_by_reference(am[0],am[1])
    lw = vehicle.last_washing

    unless lw.nil?
      if args[:datalavaggio].nil?
        fields << 'datalavaggio'
        values << "'#{lw.ending_time.strftime("%Y-%m-%d")}'"
      end
    end

    anno = args[:dataintervento].match(/^'?([0-9]{4})-.*/)[1]

    # qry = "set @nextprotocol = (select max(protocollo)+1 from autosegnalazioni);\n"
    # qry += "insert into autosegnalazioni (Anno,Protocollo,Sezione,#{fields.join(',')}) values (#{anno},@nextprotocol,'A',#{values.join(',')});\n"
    # qry += "select * from autosegnalazioni where protocollo = @nextprotocol"
    qry = [
      "set @nextprotocol = (select max(protocollo)+1 from autoodl);",
      "insert into autoodl (Anno,Protocollo,#{fields.join(',')}) values (#{anno},@nextprotocol,#{values.join(',')});",
      "select * from autoodl where protocollo = @nextprotocol;"
    ]

    ew_query_logger.info("#{@token} (new create worksheet query)=> #{qry.inspect}")
    # c = get_ew_client
    # c.automatic_close = false
    multi_query(qry)
    # prot =  c.query("select @nextprotocol")
    # sgn = c.async_result

    # c.close

    qry = "select * from autoodl where #{args.map{|f,v| "#{f} = #{v}"}.join(' and ')} order by protocollo desc limit 1"

    c = get_ew_client
    odl = c.query(qry)
    # sgn = c.query("select * from autosegnalazioni where protocollo = #{prot};")

    c.close
    if odl.first.nil?
      sleep 1
      c = get_ew_client
      odl = c.query(qry)
      # sgn = c.query("select * from autosegnalazioni where protocollo = #{prot};")

      c.close
    end

    ew_query_logger.info("#{@token} (new create worksheet result) =>  #{qry}\n#{odl.nil? ? 'null' : odl.first.inspect}")
    return odl.first
  end

  def self.edit_ew_worksheet(args)
    ew_query_logger.info("#{@token} (new edit worksheet request) => #{args.inspect}")

    args.each do |k,v|
      args[k] = 'null' if v.nil?
      args[k] = v.strftime('%Y-%m-%d') if v.is_a?(Date) || v.is_a?(DateTime)
      args[k] = "'#{args[k].gsub("'","''").gsub(';','.').gsub("\\","\\\\")[0..195]}'" if args[k].is_a?(String) && args[k] != 'null'
    end

    updates = Array.new
    args.each do |field,value|
      updates << "#{field} = #{value}"
    end

    qry = [
      "update autoodl set #{updates.join(', ')} where protocollo = #{args[:protocollo]} ;",
      "select * from autoodl where protocollo = #{args[:protocollo]};"
    ]
    # c = get_ew_client
    # sgn = c.query(qry)
    # prot =  c.query("select @nextprotocol")
    # sgn = c.async_result
    ew_query_logger.info("#{@token} (new edit worksheet query) => #{qry.inspect}")
    multi_query(qry)
    # c.close

    qry = "select * from autoodl where protocollo = #{args[:protocollo]};"
    c = get_ew_client
    odl = c.query(qry)
    # sgn = c.query("select * from autosegnalazioni where protocollo = #{prot};")
    #
    # c.close
    ew_query_logger.info("#{@token} (new edit worksheet result) => #{odl.nil? ? 'null' : odl.first.inspect}")
    return odl.first
  end

  def self.create_worksheet(payload)
    @token = SecureRandom.hex
    ew_query_logger.info("#{@token} (old worksheet method request) => #{payload.inspect}")
    ## '-1' means new one
    ## '0' means don't change
    ## 'null' means write null
    payload = payload.stringify_keys

    payload['AnnoODL'] = nil if payload['AnnoODL'] == '-1' || payload['AnnoODL'] == '0'
    payload['ProtocolloODL'] = nil if payload['ProtocolloODL'] == '-1' || payload['ProtocolloODL'] == '0'

    payload.delete('CodiceOfficina') if payload['CodiceOfficina'] == '0'
    payload.delete('CodiceAutomezzo') if payload['CodiceAutomezzo'] == '0'


    payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?
    payload['CodiceAutista'] = payload['CodiceAutista'].rjust(6,'0') unless payload['CodiceAutista'].nil?

    # payload['DataPost'] = "0" if payload['DataPost'].nil?
    # payload['UserPost'] = "0" if payload['UserPost'].nil?
    # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # payload['FlagStampato'] = false
    # payload['TipoDanno'] = "0" if payload['TipoDanno'].nil?
    # payload['FlagRiparato'] = "0" if payload['FlagRiparato'].nil?
    # payload['FlagRiparato'] = nil if payload['FlagRiparato'] == 'null'
    # payload['FlagStampato'] = nil if payload['FlagStampato'] == 'null'
    # payload['FlagSvolto'] = nil if payload['FlagSvolto'] == 'null'

    # payload['AnnoODL'] = "0" if payload['AnnoODL'].nil?
    # payload['ProtocolloODL'] = "0" if payload['ProtocolloODL'].nil?
    # payload['AnnoSGN'] = "-1" if payload['AnnoSGN'].nil?
    # payload['ProtocolloSGN'] = "-1" if payload['ProtocolloSGN'].nil?
    # payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
    # payload['CodiceOfficina'] = "0" if payload['CodiceOfficina'].nil?
    # payload['CodiceAutomezzo'] = "0" if payload['CodiceAutomezzo'].nil?
    # payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    # payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?
    #
    # # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # # payload['TipoDanno'] = '55' if payload['TipoDanno'].nil?
    # payload['FlagSvolto'] = "null" if payload['FlagSvolto'].nil?
    # payload['FlagJSONType'] = "odl"
    #
    payload.each { |k,v| payload.delete(k) if v == '0' || v == '-1' }

    if payload['ProtocolloSGN'].nil?

      payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?

      unless payload['CodiceAutomezzo'].nil?
        c = get_ew_client
        qry = "select codiceProvenienza from automezzi where codice = '#{payload['CodiceAutomezzo']}'"
        am = c.query(qry).first['codiceProvenienza'].split(' ')
        c.close
        vehicle = Vehicle.find_by_reference(am[0],am[1])

        lm = last_maintainance(vehicle)
        lc = vehicle.last_check
        payload['DataUltimaManutenzione'] = lm['DataUscitaVeicolo'].strftime("%Y-%m-%d") unless lm.nil?
        payload['DataUltimoControllo'] = lc.time.strftime("%Y-%m-%d") unless lc.nil?
      end

      payload['DataInsert'] = Date.today.strftime("%Y-%m-%d") if payload['DataInsert'].nil?

      payload['FlagRiparato'] = 'false' if payload['FlagRiparato'].nil?
      payload['FlagStampato'] = 'false' if payload['FlagStampato'].nil?
      payload['FlagSvolto'] = 'false' if payload['FlagSvolto'].nil?

      payload.delete('FlagRiparato') if payload['FlagRiparato'] == '0'
      payload.delete('FlagStampato') if payload['FlagStampato'] == '0'
      payload.delete('FlagSvolto') if payload['FlagSvolto'] == '0'

      payload['UserInsert'] = 'DASHBOARD' if payload['UserInsert'].nil?
    end
    # payload.each { |k,v| payload.delete(k) if v.nil? }

    if payload['ProtocolloODL'].nil?
      return create_ew_worksheet(
        dataintervento: payload['DataIntervento'],
        codiceanagrafico: payload['CodiceOfficina'],
        codiceautomezzo: payload['CodiceAutomezzo'].to_s,
        dataentrataveicolo: payload['DataEntrataVeicolo'],
        km: payload['Chilometraggio'],
        note: payload['Descrizione'],
        flagschedachiusa: payload['FlagSvolto'].to_s,
        codiceautista: payload['CodiceAutista'],
        datalavaggio: payload['DataLavaggio'],
        codicetipodanno: payload['TipoDanno'],
        targa: payload['CodiceTarga'],
        flagdafatturare: payload['FlagDaFatturare']
      )
    else
      args = Hash.new
      args[:protocollo] = payload['ProtocolloODL']
      args[:dataintervento] = payload['DataIntervento'] if payload.has_key? 'DataIntervento'
      args[:codiceanagrafico] = payload['CodiceOfficina'] if payload.has_key? 'CodiceOfficina'
      args[:codiceautomezzo] = payload['CodiceAutomezzo'] if payload.has_key? 'CodiceAutomezzo'
      args[:dataentrataveicolo] = payload['DataEntrataVeicolo'] if payload.has_key? 'DataEntrataVeicolo'
      args[:datauscitaveicolo] = payload['DataUscitaVeicolo'] if payload.has_key? 'DataUscitaVeicolo'
      args[:km] = payload['Chilometraggio'].to_i if payload.has_key? 'Chilometraggio'
      args[:note] = payload['Descrizione'] if payload.has_key? 'Descrizione' && payload['Descrizione'] != ''
      args[:flagschedachiusa] = payload['FlagSvolto'].to_s if payload.has_key? 'FlagSvolto'
      args[:datalavaggio] = payload['DataLavaggio'] if payload.has_key? 'DataLavaggio'
      args[:codicetipodanno] = payload['TipoDanno'] if payload.has_key? 'TipoDanno'
      args[:targa] = payload['CodiceTarga'] if payload.has_key? 'CodiceTarga'
      args[:flagdafatturare] = payload['FlagDaFatturare'] if payload.has_key? 'FlagDaFatturare'
      return edit_ew_worksheet(args)
    end
    # payload = payload.stringify_keys
    #
    # payload['AnnoODL'] = "0" if payload['AnnoODL'].nil?
    # payload['ProtocolloODL'] = "0" if payload['ProtocolloODL'].nil?
    # payload['AnnoSGN'] = "-1" if payload['AnnoSGN'].nil?
    # payload['ProtocolloSGN'] = "-1" if payload['ProtocolloSGN'].nil?
    # payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d') if payload['DataIntervento'].nil?
    # payload['CodiceOfficina'] = "0" if payload['CodiceOfficina'].nil?
    # payload['CodiceAutomezzo'] = "0" if payload['CodiceAutomezzo'].nil?
    # payload['TipoDanno'] = get_tipo_danno(payload['TipoDanno']) unless payload['TipoDanno'].nil?
    # payload['Descrizione'] = payload['Descrizione'][0..199] unless payload['Descrizione'].nil?
    #
    # # payload['DataUltimaManutenzione'] = "0000-00-00" if payload['DataUltimaManutenzione'].nil?
    # # payload['DataUltimoControllo'] = "0000-00-00" if payload['DataUltimoControllo'].nil?
    # # payload['TipoDanno'] = '55' if payload['TipoDanno'].nil?
    # payload['FlagSvolto'] = "null" if payload['FlagSvolto'].nil?
    # payload['FlagJSONType'] = "odl"
    #
    # payload.each { |k,v| payload.delete(k) if v.nil? }
    # request = HTTPI::Request.new
    # request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    # request.body = payload.to_json
    # request.headers['Content-Type'] = 'application/json; charset=utf-8'
    # special_logger.info(request)
    # response = HTTPI.post(request)
    # special_logger.info(response)
    #
    # res = JSON.parse(response.raw_body)['ProtocolloODL']
    #
    # c = get_ew_client
    # odl = c.query("select * from autoodl where protocollo = #{res}")
    # c.close
    #
    # return odl.first unless odl.count < 1

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

  def self.get_workshop_by_code(code)
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    workshop = ewc.query("select RagioneSociale from anagrafe where codice = '#{code.gsub("'","''").gsub(';','.')}'")
    ewc.close
    return workshop.first['RagioneSociale'].rstrip.lstrip unless workshop.count < 1
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

    vehicle_refs['CodiceAutista'] = ewc.query("select codice from autisti where ragionesociale = '#{opcode.to_s.gsub(';','.').gsub("'","''")}'").first
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

  def self.get_external_workshops
    query = "select * from anagrafe where codice like 'off%' order by RagioneSociale"
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    dt = ewc.query(query)
    ewc.close
    return dt
  end

  def self.get_filtered_odl(filter)
    query = <<-QUERY
      select autoodl.*,a.ragionesociale as officina,
      (select Descrizione from tabdesc where codice = autoodl.CodiceTipoDanno and gruppo = 'AUTOTIPD') as TipoDanno from autoodl
      left join anagrafe a on autoodl.codiceanagrafico = a.codice
      where #{filter}
    QUERY
    ewc = get_ew_client(ENV['RAILS_EUROS_DB'])
    ws = ewc.query(query)
    ewc.close
    ws
  end

  def self.get_tipo_danno(tipodanno, whole = false)

    if tipodanno.to_i > 0
      query = "select * from tabdesc where codice = #{tipodanno.gsub(';','.').gsub("'","''")} and gruppo = 'AUTOTIPD'"
    else
      query = "select * from tabdesc where gruppo = 'AUTOTIPD' and Descrizione = '#{tipodanno.gsub("'","''").gsub(';','.')}'"
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


  def self.multi_query(*queries)
    # Adding injection protection
    if queries[0].is_a? Array
      queries = queries[0]
    end
    queries.map! { |q| q.gsub(';','')}
    # queries.map! { |q| q.gsub("'","''")}

    c = Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: ENV['RAILS_EUROS_DB'], flags: Mysql2::Client::MULTI_STATEMENTS, collation_connection: 'latin1_swedish_ci'
    res = c.query(queries.join(';'))
    c.close
    return res
  end

  def self.get_ew_client(db = ENV['RAILS_EUROS_DB'])
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: db, collation_connection: 'latin1_swedish_ci'
  end

  def self.special_logger
    @@ew_logger ||= Logger.new("#{Rails.root}/log/eurowin_ws.log")
  end

  def self.ew_query_logger
    @@ew_logger ||= Logger.new("#{Rails.root}/log/eurowin_ws_query.log")
  end
end
