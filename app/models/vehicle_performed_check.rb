class VehiclePerformedCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check
  belongs_to :user

  scope :performed, -> { where('performed != 0')}

  enum fixvalues: ['Non eseguito','Ok','Aggiustato','Non ok','Non ok bloccante','Non applicabile']

  def self.last_reading

  end

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
    self.last_reading.value unless self.last_reading.nil?
  end

  def create_notification(operator)
    payload = Hash.new
    # payload['title'] = 'ODL/SGN'
    # payload['type'] = 'object'
    # payload['properties'] = Hash.new
    payload['AnnoODL'] = "0"
    payload['ProtocolloODL'] = "0"
    payload['AnnoSGN'] = "0"
    payload['ProtocolloSGN'] = "0"
    payload['DataIntervento'] = Date.current.strftime('%Y-%m-%d')
    # payload['DataConsegnaConcordata'] = Date.current.strftime('%m/%d/%Y')
    # payload['DataEntrataVeicolo'] = Date.current.strftime('%m/%d/%Y')
    # payload['DataUscitaVeicolo'] = Date.current.strftime('%m/%d/%Y')
    # payload['CodiceManutenzione'] = nil.to_s
    # payload['DataEntrataVeicolo'] = Date.current.strftime('%m/%d/%Y')
    payload['CodiceManutentore'] = operator.mssql_code.to_s
    payload['CodiceOfficina'] = 2.to_s
    payload['CodiceAutomezzo'] = self.vehicle_check_session.vehicle.mssql_references.last.remote_object_id.to_s
    payload['CodiceAutista'] = operator.mssql_code.to_s
    payload['TipoDannoSGN'] = self.vehicle_check.code.to_s
    payload['DescrizioneSGN'] = "Il controllo: '#{self.vehicle_check.label}' ha dato esito negativo. Valore: #{self.value}, confronto: #{self.comparation_value}."
    payload['FlagSvolto'] = "true"
    payload['FlagJSONType'] = "sgn"
#     body = <<JSON
#     {
#       "AnnoODL": "#{Date.current.strftime('%Y')}",
#       "ProtocolloODL": "",
#       "AnnoSGN": "#{Date.current.strftime('%Y')}",
#       "ProtocolloSGN": "",
#       "DataIntervento": "#{Date.current.strftime('%m/%d/%Y')}",
#       "DataConsegnaConcordata": "#{Date.current.strftime('%m/%d/%Y')}",
#       "DataEntrataVeicolo": "#{Date.current.strftime('%m/%d/%Y')}",
#       "DataUscitaVeicolo": "#{Date.current.strftime('%m/%d/%Y')}",
#       "CodiceManutenzione": "",
#       "CodiceManutentore": "#{operator.mssql_code.to_s}",
#       "CodiceOfficina": "2",
#       "CodiceAutomezzo": "#{self.vehicle_check_session.vehicle.mssql_references.last.remote_object_id}",
#       "CodiceAutista": "#{operator.mssql_code}",
#       "TipoDannoSGN": "#{self.vehicle_check.code}",
#       "DescrizioneSGN": "Il controllo: '#{self.vehicle_check.label}' ha dato esito negativo. Valore: #{self.value}, confronto: #{self.comparation_value}.",
#       "FlagSvolto": 'true',
#       "FlagJSONType": 'sgn'
#     }
# JSON
    payload = <<-JSON
{
"AnnoODL": "0",
"ProtocolloODL": "0",
"AnnoSGN": "0",
"ProtocolloSGN": "0",
"DataIntervento" : "#{Date.current.strftime('%Y-%m-%d')}",
"CodiceOfficina" : "2",
"CodiceAutomezzo" : "#{self.vehicle_check_session.vehicle.mssql_references.last.remote_object_id}",
"TipoDannoSGN" : "39",
"DescrizioneSegnalazioneSGN" : "Il controllo: '#{self.vehicle_check.label}' ha dato esito negativo. Valore: #{self.value}, confronto: #{self.comparation_value}.",
"FlagSvolto" : "false",
"FlagJSONType" : "sgn"
}
    JSON

    # payload['properties']['AnnoODL'] = Date.current.strftime('%Y')
    # payload['properties']['ProtocolloODL'] = nil.to_s
    # payload['properties']['AnnoSGN'] = Date.current.strftime('%Y')
    # payload['properties']['ProtocolloSGN'] = nil.to_s
    # payload['properties']['DataIntervento'] = Date.current.strftime('%m/%d/%Y')
    # payload['properties']['DataConsegnaConcordata'] = Date.current.strftime('%m/%d/%Y')
    # payload['properties']['DataEntrataVeicolo'] = Date.current.strftime('%m/%d/%Y')
    # payload['properties']['DataUscitaVeicolo'] = Date.current.strftime('%m/%d/%Y')
    # payload['properties']['CodiceManutenzione'] = nil.to_s
    # payload['properties']['DataEntrataVeicolo'] = Date.current.strftime('%m/%d/%Y')
    # payload['properties']['CodiceManutentore'] = operator.mssql_code.to_s
    # payload['properties']['CodiceOfficina'] = 2.to_s
    # payload['properties']['CodiceAutomezzo'] = self.vehicle_check_session.vehicle.mssql_references.last.remote_object_id.to_s
    # payload['properties']['CodiceAutista'] = operator.mssql_code.to_s
    # payload['properties']['TipoDannoSGN'] = self.vehicle_check.code.to_s
    # payload['properties']['DescrizioneSGN'] = "Il controllo: '#{self.vehicle_check.label}' ha dato esito negativo. Valore: #{self.value}, confronto: #{self.comparation_value}."
    # payload['properties']['FlagSvolto'] = 'true'
    # payload['properties']['FlagJSONType'] = 'sgn'
    # payload['required'] = ["AnnoODL","ProtocolloODL","AnnoSGN","ProtocolloSGN","DataIntervento","CodiceManutenzione","CodiceOfficina","CodiceAutomezzo","FlagSvolto","FlagJSONType"]

    request = HTTPI::Request.new
    request.url = "http://#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.body = payload
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = HTTPI.post(request)

  end

  def last_reading
    v = VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks where vehicle_check_session_id in (select id from vehicle_check_sessions where "+(self.vehicle.class == Vehicle ? "(vehicle_id = #{self.vehicle_check_session.vehicle.id} and vehicle_id is not null)" : "(external_vehicle_id = #{self.vehicle_check_session.external_vehicle.id} and external_vehicle_id is not null)")+") and vehicle_check_id = #{self.vehicle_check.id} and vehicle_performed_checks.id != #{self.id} order by time desc limit 1")
    v.first unless v.nil?
  end
end
