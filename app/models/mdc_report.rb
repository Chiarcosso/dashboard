class MdcReport < ApplicationRecord
  belongs_to :vehicle
  belongs_to :mdc_user
  belongs_to :person
  belongs_to :user
  has_many :images, class_name: 'MdcReportImage'

  def self.report_types
    return {
      'Attrezzatura': 'attrezzatura',
      'Contravvenzione': 'contravvenzione',
      'Dispositivo Protezione Individuale': 'dpi',
      'Furto': 'furto',
      'Guasto / Danno': 'guasto',
      'Incidente': 'incidente',
      'Infortunio': 'infortunio',
      'Sosta prolungata': 'sosta_prolungata'
    }
  end

  def self.offices(type)
    case type.downcase
    when 'incidente' then
      return [:hr,:logistics,:maintenance]
    when 'infortunio' then
      return [:hr,:logistics]
    when 'info' then
      return [:hr,:logistics]
    when 'sosta_prolungata' then
      return [:logistics]
    when 'avaria_mezzo' then
      return [:maintenance]
    when 'guasto' then
      return [:maintenance]
    when 'danno' then
      return [:maintenance]
    when 'furto' then
      return [:hr,:maintenance,:logistics]
    when 'altro' then
      return [:hr,:maintenance,:logistics]
    when 'contravvenzione' then
      return [:logistics,:maintenance]
    when 'attrezzatura' then
      return [:logistics,:maintenance]
    when 'dpi' then
      return [:logistics,:hr]
    else
      return []
    end
  end

  def reporter_label
    if self.mdc_user.nil?
      self.person.list_name
    else
      self.mdc_user.holder.list_name
    end
  end

  def report_label
    "#{self.report_type.tr('_',' ').capitalize}#{self.hq ? "(Sede)" : ''}"
  end

  def managed?
    !self.managed_at.nil?
  end

  def self.select_by_office(office)
    MdcReport.where("#{office.to_s} = 1")
  end

  def create_notification(user)

    # Get MSSQL vehicle
    if self.hq
      vehicle_refs = {"CodiceAutomezzo": '999', "Targa": 'SEDE'}
    else
      vehicle_refs = EurowinController::get_vehicle(self.vehicle)
    end

    # Get driver
    if self.mdc_user.nil?
      driver = user.person.mssql_references.last.remote_object_id.to_s
    else
      driver = self.mdc_user.assigned_to_person.mssql_references.last.remote_object_id.to_s
    end

    # If not referred to a vehicle milage is 0
    if self.vehicle.nil?
      mileage = '0'
    else
      mileage = self.vehicle.mileage.to_s
    end

    # Prepare payload and create notification
    payload = {
      'Descrizione': self.description,
      'UserInsert': user.person.complete_name.upcase.gsub("'","\'"),
      'UserPost': "APP MDC",
      'CodiceAutista': driver,
      'CodiceAutomezzo': vehicle_refs.with_indifferent_access['CodiceAutomezzo'],
      'CodiceTarga': vehicle_refs.with_indifferent_access['Targa'],
      'DataIntervento': self.sent_at.strftime('%Y-%m-%d'),
      'OraIntervento': self.sent_at.strftime('%H:%M:%S'),
      'TipoDanno': 'SEGNALAZIONE',
      'Chilometraggio': mileage,
      'CodiceOfficina': EurowinController::get_workshop(:workshop),
      'FlagRiparato': 'false',
      'FlagStampato': 'false',
      'FlagChiuso': 'false'
    }

    sgn = EurowinController::create_notification(payload)
    self.update(myofficina_reference: sgn['Protocollo'])
  end

end
