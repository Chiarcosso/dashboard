class MdcReport < ApplicationRecord
  belongs_to :vehicle
  belongs_to :mdc_user
  belongs_to :user
  has_many :images, class_name: 'MdcReportImage'


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
