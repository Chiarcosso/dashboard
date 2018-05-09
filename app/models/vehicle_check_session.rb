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
    "#{self.actual_vehicle.plate}#{self.worksheet.nil?? '' : " (ODL nr. #{self.worksheet.number}"}"
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

  def create_worksheet(user)
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
    payload['CodiceOfficina'] = 'OFF000'+workshop.first['id'].to_s
    payload['CodiceAutomezzo'] = self.vehicle.mssql_references.last.remote_object_id.to_s
    payload['FlagSvolto'] = "false"
    payload['FlagJSONType'] = "odl"

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload.to_json
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = JSON.parse(HTTPI.post(request))['ProtocolloODL'].to_i
    self.update(myofficina_reference: res, worksheet: Worksheet.create(code: "EWC*#{res}", vehicle: self.vehicle, vehicle_type: self.vehicle.class.to_s, opening_date: Date.current))

  end

  def get_client
    TinyTds::Client.new username: ENV['RAILS_MSSQL_USER'], password: ENV['RAILS_MSSQL_PASS'], host: ENV['RAILS_MSSQL_HOST'], port: ENV['RAILS_MSSQL_PORT'], database: ENV['RAILS_MSSQL_DB']
  end

  # def self.get_client
  #   Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: ENV['RAILS_EUROS_DB']
  # end
end
