class VehicleCheckSession < ApplicationRecord
  resourcify
  belongs_to :operator, class_name: User
  belongs_to :worksheet
  belongs_to :vehicle
  belongs_to :external_vehicle
  has_many :vehicle_performed_checks, :dependent => :destroy

  scope :opened, -> { where(finished: nil) }
  scope :closed, -> { where('finished is not null').order(finished: :desc) }
  scope :last_week, -> { where("date > '#{(Date.today - 7).strftime('%Y-%m-%d')}'") }

  def actual_vehicle
    if self.vehicle.nil?
      self.external_vehicle
    else
      self.vehicle
    end
  end

  def vehicle_ordered_performed_checks
    res = Hash.new
    self.vehicle_performed_checks.sort_by{ |vc| [ vc.performed?.to_s, vc.mandatory ? 0 : 1, -vc.vehicle_check.importance, vc.vehicle_check.label ] }.each do |vpc|
      res[vpc.vehicle_check.code] = Array.new if res[vpc.vehicle_check.code].nil?
      res[vpc.vehicle_check.code] << vpc
    end
    res
    # self.vehicle_performed_checks.sort_by{ |vc| [ !vc.mandatory, !vc.performed.to_s, -vc.vehicle_check.importance, vc.vehicle_check.label ] }
    #.order({mandatory: :desc, performed: :asc, importance: :desc, label: :asc})
  end

  def destination_label
    "#{self.actual_vehicle.plate}#{self.worksheet.nil?? '' : " (ODL nr. #{self.worksheet.number})"}"
  end

  def theoretical_duration_label
    "#{(self.theoretical_duration/60).floor.to_s.rjust(2,'0')}:#{(self.theoretical_duration%60).to_s.rjust(2,'0')}"
  end

  def real_duration_label
    "#{(self.real_duration.to_i/3600).floor.to_s.rjust(2,'0')}:#{((self.real_duration.to_i/60)%60).floor.to_s.rjust(2,'0')}:#{(self.real_duration.to_i%60).floor.to_s.rjust(2,'0')}"
  end

  def recalculate_expected_time
    self.theoretical_duration = self.actual_vehicle.vehicle_checks.map{ |c| c.duration }.inject(0,:+)
    self.save
  end

  def recalculate_real_time
    # self.real_duration = self.vehicle_performed_checks.map{ |c| c.duration }.inject(0,:+)
    # self.save
  end

  def self.create_worksheet(user,vehicle)

    workshop = get_ew_client(ENV['RAILS_EUROS_DB']).query("select codice from anagrafe where ragioneSociale = 'PUNTO CHECK-UP'")

    o = get_ms_client.execute("select id from manutentori where idautista = "+user.person.mssql_references.last.remote_object_id.to_s)

    if o.count > 0
      opcode = o.first['id'].to_s.rjust(4,'0')

      operator = get_ew_client('common').query("select codice from operatori where codice = '#{opcode}'")
    else
      operator = []
    end

    unless vehicle.last_driver.nil?

      opcode = get_ms_client.execute("select nominativo from autisti where idautista = "+vehicle.last_driver.mssql_references.last.remote_object_id.to_s).first['nominativo']

    end

    driver = get_ew_client(ENV['RAILS_EUROS_DB']).query("select codice from autisti where ragionesociale = '#{opcode}'")

    payload = Hash.new

    payload['AnnoODL'] = "0"
    payload['ProtocolloODL'] = "0"
    payload['AnnoSGN'] = "0"
    payload['ProtocolloSGN'] = "0"
    payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d')
    payload['DataEntrataVeicolo'] = Date.current.strftime('%Y-%m-%d')
    payload['CodiceManutentore'] = operator.first['codice'].to_s unless operator.count == 0
    payload['CodiceOfficina'] = workshop.first['codice'].to_s
    payload['CodiceAutomezzo'] = vehicle.mssql_references.last.remote_object_id.to_s
    payload['CodiceTarga'] = vehicle.plate
    payload['Chilometraggio'] = vehicle.mileage.to_s
    payload['DataLavaggio'] = vehicle.last_washing.ending_time.strftime('%Y-%m-%d') unless vehicle.last_washing.nil?
    payload['TipoDanno'] = '55'
    payload['Descrizione'] = 'Controlli'
    payload['FlagSvolto'] = "false"
    payload['FlagJSONType'] = "odl"

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = JSON.parse(HTTPI.post(request).body)['ProtocolloODL'].to_i
    # self.update(myofficina_reference: res, worksheet: Worksheet.create(code: "EWC*#{res}", vehicle: self.vehicle, vehicle_type: self.vehicle.class.to_s, opening_date: Date.current))

  end

  def close_worksheet(user)

    payload = Hash.new

    payload['AnnoODL'] = self.created_at.strftime('%Y')
    payload['ProtocolloODL'] = self.myofficina_reference.to_s
    payload['AnnoSGN'] = "0"
    payload['ProtocolloSGN'] = "0"
    payload['DataIntervento'] = "0000-00-00"
    payload['DataUscitaVeicolo'] = Date.current.strftime('%Y-%m-%d')
    payload['CodiceOfficina'] = "0"
    payload['CodiceAutomezzo'] = "0"
    payload['FlagSvolto'] = "true"
    payload['FlagJSONType'] = "odl"

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = JSON.parse(HTTPI.post(request).body)['ProtocolloODL'].to_i
    # self.update(myofficina_reference: res, worksheet: Worksheet.create(code: "EWC*#{res}", vehicle: self.vehicle, vehicle_type: self.vehicle.class.to_s, opening_date: Date.current))
    self.worksheet.update(exit_time: DateTime.now)

    self.vehicle_performed_checks.each do |vpc|
      vpc.create_notification(user)
    end

  end

  def self.get_ms_client
    TinyTds::Client.new username: ENV['RAILS_MSSQL_USER'], password: ENV['RAILS_MSSQL_PASS'], host: ENV['RAILS_MSSQL_HOST'], port: ENV['RAILS_MSSQL_PORT'], database: ENV['RAILS_MSSQL_DB']
  end

  def self.get_ew_client(db)
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: db
  end
end
