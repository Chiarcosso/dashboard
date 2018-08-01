class WorkshopMailer < ApplicationMailer

  default to: 'officina@chiarcosso.it'

  def send_worksheet(ws)

    # notify_to = ['officina@chiarcosso.it','ufficioit@chiarcosso.com']
    notify_to = ['schede.officina@chiarcosso.com']
    vehicle = ws.vehicle

    message = "ODL nr. #{ws.number}\n\n"\
    "#{vehicle.plate} - #{vehicle.class == Vehicle ? vehicle.model.complete_name : vehicle.owner.complete_name}\n\n"\
    "Data entrata: #{ws.opening_date.strftime("%Y/%m/%d")}\n"\
    "Data uscita: #{ws.exit_time.strftime("%Y/%m/%d")}\n"\
    "Durata totale: #{ws.real_duration_label}"

    attachments["odl_nr_#{ws.number}.pdf"] = {:mime_type => 'application/pdf', :content => ws.sheet.render }
    mail(body: message, subject: "ODL nr. #{ws.number} - #{ws.vehicle.plate} - #{ws.notes}", to: notify_to)

  end

end
