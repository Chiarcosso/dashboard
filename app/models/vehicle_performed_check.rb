class VehiclePerformedCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check
  has_one :worksheet, through: :vehicle_check_session
  has_one :vehicle, :through => :vehicle_check_session
  belongs_to :user
  has_one :operator, :through => :user, source: :person

  scope :performed, -> { where('performed != 0')}
  scope :not_ok, -> { where('performed = 4 or performed = 5')}
  scope :not_performed, -> { where('performed = 0')}
  scope :ok, -> { where('performed = 1')}
  scope :fixed, -> { where('performed = 2')}
  scope :unappliable, -> { where('performed = 3')}
  scope :unfixed, -> { where('performed = 4')}
  scope :blocking, -> { where('performed = 5')}

  # scope :last_checks, ->(vehicle) { joins(:vehicle_check_session).where('vehicle_check_sessions.vehicle_id = ?',vehicle.id).group(:vehicle_check_id).having('vehicle_performed_checks.time = max(vehicle_performed_checks.time)') }

  enum fixvalues: ['Non eseguito','Ok','Eseguito/Aggiustato','Non applicabile','Non ok','Non ok bloccante']

  def result_label
    VehiclePerformedCheck.fixvalues.key(self.performed)
  end

  def blocking?
    self.performed == VehiclePerformedCheck.fixvalues['Non ok bloccante'].to_i
  end

  def km
    self.worksheet.mileage unless self.worksheet.nil?
  end

  def self.last_check(vehicle,check)
    query = <<-QUERY
      select * from vehicle_performed_checks
      group by vehicle_id, vehcile_check_d
      having vehicle_id = #{vehicle.id} and vehicle_check_is = #{check.id}
      and time = max(time)
    QUERY
    VehiclePerformedCheck.find_by_sql(query)
  end

  def last_reading
    v = VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks "\
    "where vehicle_check_session_id in "\
      "(select id from vehicle_check_sessions "\
        "where "+(self.vehicle.class == Vehicle ? "(vehicle_id = #{self.vehicle_check_session.vehicle.id} and vehicle_id is not null)" : "(external_vehicle_id = #{self.vehicle_check_session.external_vehicle.id} and external_vehicle_id is not null)")+") "\
          "and vehicle_check_id = #{self.vehicle_check.id} and vehicle_performed_checks.id != #{self.id} "\
          "order by time desc limit 1")
    v.first unless v.nil?
  end

  def last_valid_reading
    # unless self.last_reading.nil?
    #   self.last_reading.performed == 1 ? self.last_reading : self.last_reading.last_valid_reading
    # end
    v = VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks "\
    "where vehicle_check_session_id in "\
      "(select id from vehicle_check_sessions "\
        "where "+(self.vehicle.class == Vehicle ? "(vehicle_id = #{self.vehicle_check_session.vehicle.id} and vehicle_id is not null)" : "(external_vehicle_id = #{self.vehicle_check_session.external_vehicle.id} and external_vehicle_id is not null)")+") "\
          "and vehicle_check_id = #{self.vehicle_check.id} and vehicle_performed_checks.id != #{self.id} and performed = 1 "\
          "order by time desc limit 1")
    v.first unless v.nil?
  end

  # def self.last_checks(vehicle)
  #   VehiclePerformedCheck.find_by_sql('select * from vehicle_performed_checks inner join vehicle_check_sessions on vehicle_performed_checks.vehicle_check_session_id = vehicle_check_sessions.id ')
  # end



  def select_options
    self.vehicle_check.select_options
  end

  def performed?
    self.performed != 0
  end

  def datatype
    self.vehicle_check.datatype
  end

  def vehicle
    self.vehicle_check_session.vehicle.nil?? self.vehicle_check_session.external_vehicle : self.vehicle_check_session.vehicle
  end

  def status_style
    # return 'background: #f99' if (self.mandatory and !self.performed?) or self.blocking?
    return 'background: #f99' if self.blocking?
    return 'background: #ff9' if self.performed == 4
    return 'background: #9f9' if self.performed?
  end

  def comparation_value
    self.last_valid_reading.value unless self.last_valid_reading.nil?
  end

  def message
    measure_unit = self.vehicle_check.measure_unit.to_s
    lvr = self.last_valid_reading
    case self.performed
    when 0 then
      "#{self.vehicle_check.label} non è stato eseguito."
    when 1 then
      "#{self.vehicle_check.label} a posto. Risultato: #{self.value}#{measure_unit}, ultimo riferimento valido: #{lvr.nil?? 'Non trovato' : lvr.value+measure_unit} #{lvr.nil?? '' : '('+lvr.time.strftime('%d/%m/%Y')+')'}."
    when 2 then
      "#{self.vehicle_check.label} aggiustato.#{self.notes.nil?? '' : ' '+self.notes+'.'}"
    when 3 then
      "#{self.vehicle_check.label} non applicabile.#{self.notes.nil?? '' : ' '+self.notes+'.'}"
    when 4 then
      "#{self.vehicle_check.label} non a posto. Risultato: #{self.value}#{measure_unit}, ultimo riferimento valido: #{lvr.nil?? 'Non trovato' : lvr.value.to_s+measure_unit} #{lvr.nil?? '' : '('+lvr.time.strftime('%d/%m/%Y')+')'}..#{self.notes.nil?? '' : ' '+self.notes+'.'}"
    when 5 then
      "BLOCCANTE -- #{self.vehicle_check.label}: #{self.value}#{measure_unit}, ultimo riferimento valido: #{lvr.nil?? 'Non trovato' : lvr.value.to_s+measure_unit} #{lvr.nil?? '' : '('+lvr.time.strftime('%d/%m/%Y')+')'}..#{self.notes.nil?? '' : ' '+self.notes.to_s+'.'}"
    end
  end

  def notify_to
    self.vehicle_check.notify_to
  end

  def create_notification(user)

    #if the result is 'Aggiustato', 'Non ok' o 'Bloccante'
    unless self.performed == 0 or self.performed == 1 or self.performed == 3

      #get some info and ids
      vcs = self.vehicle_check_session
      vehicle = self.vehicle
      mssql = vehicle.mssql_references.first

      #differentiate tables for the query
      case mssql.remote_object_table
      when 'Veicoli' then
        field = 'idveicolo'
      when 'Rimorchi1' then
        field = 'idrimorchio'
      when 'Altri Mezzi' then
        field = 'COD'
      end

      #get the workshop from eurowin
      ewc = VehiclePerformedCheck.get_ew_client(ENV['RAILS_EUROS_DB'])
      workshop = ewc.query("select codice from anagrafe where ragioneSociale = 'PUNTO CHECK-UP'")
      ewc.close

      #get the operator code
      opcode = VehiclePerformedCheck.get_ms_client.execute("select nominativo from autisti where idautista = "+user.person.mssql_references.last.remote_object_id.to_s).first['nominativo'].to_s.gsub("'","''") unless vehicle.last_driver.nil?

      # plate = VehiclePerformedCheck.get_ms_client.execute("select targa from #{mssql.remote_object_table} where #{field} = #{mssql.remote_object_id}").first['targa'] unless vehicle.last_driver.nil?
      ewc = VehiclePerformedCheck.get_ew_client(ENV['RAILS_EUROS_DB'])
      driver = ewc.query("select codice from autisti where ragionesociale = '#{opcode}'")
      ewc.close


      case self.performed
      when 5 then     #blocking damage
        #get the last open odl
        odlr = EurowinController::last_open_odl_not(self.vehicle_check_session.myofficina_reference)

        #if there aren't create one
        if !odlr.nil? && odlr.count > 0
          odl = odlr['Protocollo'].to_s
          odl_year = odlr['Anno'].to_s
        else
          odl = VehicleCheckSession.create_worksheet(user,vehicle,'OFFICINA INTERNA','55',"Bloccante: #{self.vehicle_check.label}"[0..99])
          odl_year = Date.today.strftime('%Y')
        end
      when 4 then   #damaged
        #bind to no odl
        odl = "-1"
        odl_year = "-1"
      when 2 then   #repaired
        #bind to same odl as the session
        odl =  vcs.myofficina_reference.to_i.to_s
        odl_year = vcs.created_at.strftime('%Y')
      else
        raise 'Questo controllo non necessita segnalazione.'
      end

      payload = Hash.new

      payload['AnnoODL'] = odl_year.to_s
      payload['ProtocolloODL'] = odl.to_s
      payload['AnnoSGN'] = self.myofficina_reference.nil?? "0" : vcs.created_at.strftime('%Y')
      payload['ProtocolloSGN'] = self.myofficina_reference.nil?? "0" : self.myofficina_reference.to_s
      payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d')
      payload['DataInsert'] = Date.current.strftime('%Y-%m-%d')
      payload['UserInsert'] = user.person.complete_name.upcase
      payload['DataPost'] = Date.current.strftime('%Y-%m-%d')
      payload['UserPost'] = 'PUNTO CHECKUP'
      # payload['DataUltimaManutenzione'] = "0000-00-00"
      # payload['DataUltimoControllo'] = "0000-00-00"
      payload['FlagStampato'] = 'false'
      payload['CodiceOfficina'] = workshop.first['codice'].to_s
      payload['CodiceAutista'] = driver.first['codice'] if driver.count > 0
      payload['CodiceAutomezzo'] = vehicle.mssql_references.last.remote_object_id.to_s
      payload['CodiceTarga'] = vehicle.plate
      payload['Chilometraggio'] = vehicle.mileage.to_s
      payload['TipoDanno'] = '55'
      payload['Descrizione'] = "#{self.vehicle_check.label}#{self.notes.nil? ? '' : " - #{self.notes}"}"[0..199]
      payload['FlagRiparato'] = self.performed == 2 ? "true" : "false"
      payload['FlagSvolto'] = self.performed == 2 ? "true" : "false"
      payload['FlagJSONType'] = "sgn"

      res = EurowinController::create_notification(payload)

      VehiclePerformedCheck.special_logger.info(res)
      self.update(myofficina_reference: res['Protocollo'].to_i,myofficina_odl_reference: res['SchedaInterventoProtocollo'].to_i)


    end

  end

  def self.get_ms_client
    TinyTds::Client.new username: ENV['RAILS_MSSQL_USER'], password: ENV['RAILS_MSSQL_PASS'], host: ENV['RAILS_MSSQL_HOST'], port: ENV['RAILS_MSSQL_PORT'], database: ENV['RAILS_MSSQL_DB']
  end

  def self.get_ew_client(db)
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: db
  end


  def self.special_logger
    @@ew_logger ||= Logger.new("#{Rails.root}/log/eurowin_ws.log")
  end
end
