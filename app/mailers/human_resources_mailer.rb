class HumanResourcesMailer < ApplicationMailer


  default to: 'personale@chiarcosso.it'
  # default to: 'ufficioit@chiarcosso.com'

  def workshop_hours(date = Date.yesterday)

    text = "\nOre officina del #{date.strftime("%d/%m/%Y")}\n"

    Person.present_mechanics(date).order(surname: :asc).each do |person|
      text += "\n\n#{person.list_name}:\n"
      timesheets = TimesheetRecord.where(person: person)
          .where("timesheet_records.start between '#{date.strftime("%Y-%m-%d")} 00:00:00' and '#{date.strftime("%Y-%m-%d")} 23:59:59'")
          .order(:start => :asc)

      if timesheets.count < 1
        text += "    non ci sono operazioni in questa giornata.\n\n"
      end

      total = 0
      timesheets.each_with_index do |t,i|

        total += t.minutes.to_i
        ws = t.workshop_operation.worksheet unless t.workshop_operation.nil?
        odl = "    ODL nr. #{ws.number} - #{ws.vehicle.plate}" unless ws.nil?
        notification = t.workshop_operation.ew_notification unless t.workshop_operation.nil?
        odl += " - #{notification['DescrizioneSegnalazione']}" unless notification.nil?
        text += odl.to_s == '' ? "    Operazione fuori scheda\n" : "#{odl.tr("\n",' ')}\n"

        if t.stop.nil?
          minutes = '        Non conclusa '
        else
          minutes = "        #{t.minutes} min.#{" ".rjust(7 - "#{t.minutes}".length)}"
        end
        text += "#{minutes}#{t.id} - #{t.description} #{t.workshop_operation_id.nil? ? '' : "(#{t.workshop_operation_id})"} - "
        text += "(#{t.start.strftime("%H:%M:%S")} -> #{t.stop.nil? ? 'Non conclusa' : t.stop.strftime("%H:%M:%S")})\n\n"

      end

      # Summary
      hrs = (total / 60).floor
      mins = total % 60

      pr = PresenceRecord.actual_day_time_label(date, person)
      if pr.nil?
        pr_text = "Non sono presenti timbrature"
      else
        pr_text= "#{pr}"
      end

      ws = WorkingSchedule.get_schedule(date,person)
      if ws.nil?
        ws_text = "Non è stato concordato un orario per questa giornata."
      else
        ws_text = ws.expected_hours_label
      end

      text += "Totale: #{hrs.to_s.rjust(2,'0')}:#{mins.to_s.rjust(2,'0')}\n"
      text += "Totale timbrature: #{pr_text}\n"
      text += "Totale concordato: #{ws_text}\n"
    end
    mail(body: text, subject: "Ore officina del #{date.strftime("%d/%m/%Y")}")
  end

  def vacation_request(application)
    return if Rails.env == "development"
    @application = application
    attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    mail(body: application.text, subject: 'Richiesta '+application.type+', '+application.person.complete_name)
  #   HumanResourcesMailer::ADDRESS_LIST.each do |address|
  #     m.to = address
  #     begin
  #     self.deliver_now
  #     puts m
  #     rescue EOFError,
  #             IOError,
  #             TimeoutError,
  #             Errno::ECONNRESET,
  #             Errno::ECONNABORTED,
  #             Errno::EPIPE,
  #             Errno::ETIMEDOUT,
  #             Net::SMTPAuthenticationError,
  #             Net::SMTPServerBusy,
  #             Net::SMTPSyntaxError,
  #             Net::SMTPUnknownError,
  #             OpenSSL::SSL::SSLError => e
  #             log_exception(e, options)
  #       puts
  #       puts 'An error occurred sending mail..'
  #       puts  e.inspect
  #       puts
  #     end
  #   end
  #
  end

  def journal_check(text)
    mail(body: text, subject: 'Sincronizzazione dashboard/giornale')
  end
end
