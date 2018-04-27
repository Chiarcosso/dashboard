class VehiclePerformedCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle_check_session
  belongs_to :vehicle_check
  belongs_to :user

  enum fixvalues: ['Seleziona','Ok','Aggiustato','Non ok marginale','Non ok grave','Non ok bloccante']

  def self.last_reading

  end

  def vehicle
    self.vehicle_check_session.vehicle.nil?? self.vehicle_check_session.external_vehicle : self.vehicle_check_session.vehicle
  end

  def status_style
    'background: #f99' if self.mandatory
    'background: #9f9' if self.performed
  end

  def create_notification(operator)
    payload = Hash.new
    payload['AnnoODL'] = Date.current.strftime('%Y')
    payload['ProtocolloODL'] = nil.to_s
    payload['AnnoSGN'] = Date.current.strftime('%Y')
    payload['ProtocolloSGN'] = nil.to_s
    payload['DataIntervento'] = Date.current.strftime('%m/%d/%Y')
    payload['DataConsegnaConcordata'] = Date.current.strftime('%m/%d/%Y')
    payload['DataEntrataVeicolo'] = Date.current.strftime('%m/%d/%Y')
    payload['DataUscitaVeicolo'] = Date.current.strftime('%m/%d/%Y')
    payload['Codicemanutenzione'] = nil.to_s
    payload['DataEntrataVeicolo'] = Date.current.strftime('%m/%d/%Y')
    payload['CodiceManutentore'] = operator.mssql_code
    payload['CodiceOfficina'] = 2
    payload['CodiceAutomezzo'] = self.vehicle_check_session.vehicle.mssql_references.last.remote_object_id
    payload['CodiceAutista'] = operator.mssql_code
    payload['TipoDannoSGN'] = self.vehicle_check.code
    payload['DescrizioneSGN'] = "Il controllo: '#{self.vehicle_check.label}' ha dato esito negativo. Valore: #{self.value}, confronto: #{self.vehicle_check.comparation_value}."
    payload['FlagSvolto'] = 'true'
    payload['FlagJSONType'] = 'sgn'


    request = HTTPI::Request.new
    request.url = "#{ENV['RAILS_EUROS_HOST']}:#{ENV['RAILS_EUROS_WS_PORT']}"
    request.data = payload
    request.headers['Content-Type'] = 'application/json; charset=utf-8'
    res = HTTPI.post(request)

    byebug
  end

  def last_reading
    v = VehiclePerformedCheck.find_by_sql("select * from vehicle_performed_checks where vehicle_check_session_id in (select id from vehicle_check_sessions where "+(self.vehicle.class == Vehicle ? "(vehicle_id = #{self.vehicle_check_session.vehicle.id} and vehicle_id is not null)" : "(external_vehicle_id = #{self.vehicle_check_session.external_vehicle.id} and external_vehicle_id is not null)")+") and vehicle_check_id = #{self.vehicle_check.id} and vehicle_performed_checks.id != #{self.id} order by time desc limit 1")
    v.first unless v.nil?
  end
end
