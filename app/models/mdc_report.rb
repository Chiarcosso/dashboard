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

  def managed?
    !self.managed_at.nil?
  end

  def self.select_by_office(office)
    MdcReport.where("#{office.to_s} = 1")
  end

  def create_notification(user)

    # Get MSSQL vehicle
    vehicle_refs = EurowinController::get_vehicle(self.vehicle)

    # Prepare payload and create notification
    payload = {
      'Descrizione': self.description,
      'UserInsert': user.person.complete_name.upcase.gsub("'","\'"),
      'UserPost': "APP MDC",
      'CodiceAutista': self.mdc_user.assigned_to_person.mssql_references.last.remote_object_id.to_s,
      'CodiceAutomezzo': vehicle_refs['CodiceAutomezzo'],
      'CodiceTarga': vehicle_refs['Targa'],
      'TipoDanno': 'SEGNALAZIONE',
      'Chilometraggio': self.vehicle.mileage.to_s,
      'CodiceOfficina': EurowinController::get_workshop(:workshop),
      'FlagRiparato': 'false',
      'FlagStampato': 'false',
      'FlagChiuso': 'false'
    }

    sgn = EurowinController::create_notification(payload)
    self.update(myofficina_reference: sgn['Protocollo'])
  end

end
