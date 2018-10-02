class WorkshopMailer < ApplicationMailer

  default to: 'officina@chiarcosso.it'

  def send_worksheet(ws,pdf)

    # notify_to = ['officina@chiarcosso.it','ufficioit@chiarcosso.com']
    notify_to = ['schede.officina@chiarcosso.com']
    vehicle = ws.vehicle

    message = "ODL nr. #{ws.number}\n\n"\
    "#{vehicle.plate} - #{vehicle.class == Vehicle ? vehicle.model.complete_name : vehicle.owner.complete_name}\n\n"\
    "Data entrata: #{ws.opening_date.strftime("%Y/%m/%d")}\n"\
    "Data uscita: #{ws.exit_time.strftime("%Y/%m/%d")}\n"\
    "Durata totale: #{ws.real_duration_label}"

    attachments["odl_nr_#{ws.number}.pdf"] = {:mime_type => 'application/pdf', :content => pdf.render }
    mail(body: message, subject: "ODL nr. #{ws.number} - #{ws.vehicle.plate} - #{ws.notes}", to: notify_to)

    send_to_logistics(ws)

  end

  def send_to_logistics(ws)
    notify_to = ['mezzipronti@chiarcosso.com']
    vehicle = ws.vehicle

    message = "#{Time.now.strftime("%d/%m/%Y %H:%M:%S")} - Il mezzo targato #{vehicle.plate} è uscito dall'officina.\n\n"\
          "#{vehicle.complete_name}"
    mail(body: message, subject: "Il mezzo targato #{ws.vehicle.plate} è uscito dall'officina.", to: notify_to)

  end

end
