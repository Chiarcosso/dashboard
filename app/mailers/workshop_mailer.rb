class WorkshopMailer < ApplicationMailer

  default to: 'officina@chiarcosso.it'

  def send_worksheet(ws,pdf)
    return if Rails.env == "development"
    # notify_to = ['officina@chiarcosso.it','ufficioit@chiarcosso.com']
    notify_to = ['schede.officina@chiarcosso.com']
    vehicle = ws.vehicle

    message = "ODL nr. #{ws.number}\n\n"\
    "#{vehicle.plate} - #{vehicle.class == Vehicle ? vehicle.model.complete_name : vehicle.owner.complete_name}\n\n"\
    "Data entrata: #{ws.opening_date.nil? ? 'N/D' : ws.opening_date.strftime("%Y/%m/%d")}\n"\
    "Data uscita: #{ws.exit_time.nil? ? 'N/D' : ws.exit_time.strftime("%Y/%m/%d")}\n"\
    "Durata totale: #{ws.real_duration_label}"

    attachments["odl_nr_#{ws.number}.pdf"] = {:mime_type => 'application/pdf', :content => pdf.render }
    mail(body: message, subject: "#{ws.station_label} - ODL nr. #{ws.number} - #{ws.vehicle.plate} - #{ws.notes}", to: notify_to)

  end

  def send_to_logistics(ws)
    return if Rails.env == "development"
    notify_to = ['mezzipronti@chiarcosso.com']
    vehicle = ws.vehicle
    case ws.station
    when 'workshop' then
      station = "uscito dall\'officina"
    when 'carwash' then
      station = 'uscito dal punto check-up'
    else
      station = 'pronto (officina non specificata)'
    end

    message = <<-MESSAGE
    #{Time.now.strftime("%d/%m/%Y %H:%M:%S")} - Il mezzo targato #{vehicle.plate} è #{station}.

    #{vehicle.complete_name}

    ODL nr. #{ws.number}.

    MESSAGE

    mail(body: message, subject: "Il mezzo targato #{ws.vehicle.plate} è #{station}.", to: notify_to)

  end

  def notify_moving_sgn(sgn,old_odl)
    return if Rails.env == "development"
    notify_to = ['officina@chiarcosso.it','ufficioit@chiarcosso.com']

    if old_odl.nil?
      subject = "#{sgn['Targa']} - La segnalazione nr. #{sgn['Protocollo']} è stata assegnata all'ODL interno nr. #{sgn['SchedaInterventoProtocollo']}"
      message = <<-MESSAGE
      #{Time.now.strftime("%d/%m/%Y %H:%M:%S")} -- #{sgn['Targa']}
      La segnalazione nr. #{sgn['Protocollo']} è stata assegnata all'ODL interno nr. #{sgn['SchedaInterventoProtocollo']}.

      #{sgn['DescrizioneSegnalazione']}

      MESSAGE
    else
      workshop = EurowinController::get_workshop_by_code(old_odl['CodiceAnagrafico'])
      subject = "#{sgn['Targa']} - La segnalazione nr. #{sgn['Protocollo']} è stata spostata dall'ODL nr. #{old_odl['Protocollo']} (#{workshop}) all'ODL interno nr. #{sgn['SchedaInterventoProtocollo']}"
      message = <<-MESSAGE
      #{Time.now.strftime("%d/%m/%Y %H:%M:%S")} -- #{sgn['Targa']}
      La segnalazione nr. #{sgn['Protocollo']} è stata spostata dall'ODL nr. #{old_odl['Protocollo']} (#{workshop}) all'ODL interno nr. #{sgn['SchedaInterventoProtocollo']}.

      #{sgn['DescrizioneSegnalazione']}

      MESSAGE
    end
    mail(body: message, subject: subject, to: notify_to)

  end

end
