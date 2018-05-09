class VehiclePerformedCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check
  has_one :vehicle, :through => :vehicle_check_session
  belongs_to :user

  scope :performed, -> { where('performed != 0')}
  scope :not_ok, -> { where('performed != 0 and performed != 1 and performed != 2')}
  scope :not_performed, -> { where('performed = 0')}
  scope :ok, -> { where('performed = 1')}
  scope :fixed, -> { where('performed = 2')}
  scope :unfixed, -> { where('performed = 3')}
  scope :blocking, -> { where('performed = 4')}
  scope :unappliable, -> { where('performed = 5')}
  # scope :last_checks, ->(vehicle) { joins(:vehicle_check_session).where('vehicle_check_sessions.vehicle_id = ?',vehicle.id).group(:vehicle_check_id).having('vehicle_performed_checks.time = max(vehicle_performed_checks.time)') }

  enum fixvalues: ['Non eseguito','Ok','Aggiustato','Non ok','Non ok bloccante','Non applicabile']

  def last_reading
    v = VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks where vehicle_check_session_id in (select id from vehicle_check_sessions where "+(self.vehicle.class == Vehicle ? "(vehicle_id = #{self.vehicle_check_session.vehicle.id} and vehicle_id is not null)" : "(external_vehicle_id = #{self.vehicle_check_session.external_vehicle.id} and external_vehicle_id is not null)")+") and vehicle_check_id = #{self.vehicle_check.id} and vehicle_performed_checks.id != #{self.id} order by time desc limit 1")
    v.first unless v.nil?
  end

  def last_valid_reading
    unless self.last_reading.nil?
      self.last_reading.performed == 1 ? self.last_reading : self.last_reading.last_valid_reading
    end
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
    'background: #f99' if self.mandatory
    'background: #9f9' if self.performed?
  end

  def comparation_value
    self.last_valid_reading.value unless self.last_valid_reading.nil?
  end

  def create_notification(user)
    client = get_client
    workshop = get_client.execute("select id from officine where fornitore = 'PUNTO CHECK-UP'")

    operator = get_client.execute("select id from manutentori where idautista = #{user.person.mssql_references.last.remote_object_id}")

    payload = Hash.new

    payload['AnnoODL'] = "0"
    payload['ProtocolloODL'] = "0"
    payload['AnnoSGN'] = "0"
    payload['ProtocolloSGN'] = "0"
    payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d')
    payload['CodiceManutentore'] = operator.first['id'].to_s unless operator.count == 0
    payload['CodiceAutomezzo'] = self.vehicle.mssql_references.last.remote_object_id.to_s
    payload['FlagSvolto'] = "false"
    payload['FlagJSONType'] = "sgn"

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = JSON.parse(HTTPI.post(request))['ProtocolloSGN'].to_i
    self.update(myofficina_reference: res)

  end

  def get_client
    TinyTds::Client.new username: ENV['RAILS_MSSQL_USER'], password: ENV['RAILS_MSSQL_PASS'], host: ENV['RAILS_MSSQL_HOST'], port: ENV['RAILS_MSSQL_PORT'], database: ENV['RAILS_MSSQL_DB']
  end

  # def self.get_client
  #   Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: ENV['RAILS_EUROS_DB']
  # end


end
