class StorageMailer < ApplicationMailer


  default to: 'magazzino@chiarcosso.it'

  def reserve_alert(article)
    return if Rails.env == "development"
    text = "L'articolo #{article.complete_name} è sceso sotto la scorta minima di #{article.minimal_reserve}."
    text += "\n\nQuesta è una mail automatica interna. Non rispondere direttamente a questo indirizzo.\nIn caso di problemi scrivere a ufficioit@chiarcosso.com o contattare direttamente l'amministratore del sistema."
    mail(body: text, subject: 'Avviso scorta '+article.complete_name)
  end

  def gear_request(application,department)
    return if Rails.env == "development"
    @application = application
    # attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    case department
    when :hr
      address = 'richiesta.dpi@chiarcosso.com'
    when :storage
      address = 'richiesta.materiali@chiarcosso.com'
    else
      address = 'magazzino@chiarcosso.it'
    end
    mail(body: application.text(department), subject: 'Richiesta dotazione, '+application.person.complete_name, to: address)
    # StorageMailer::ADDRESS_LIST.each do |address|
    #   m.to = address
    #   begin
    #   self.deliver_now
    #   puts m
    #   rescue EOFError,
    #           IOError,
    #           Errno::ECONNRESET,
    #           Errno::ECONNABORTED,
    #           Errno::EPIPE,
    #           Errno::ETIMEDOUT,
    #           Net::SMTPAuthenticationError,
    #           Net::SMTPServerBusy,
    #           Net::SMTPSyntaxError,
    #           Net::SMTPUnknownError,
    #           OpenSSL::SSL::SSLError => e
    #           log_exception(e, options)
    #     puts
    #     puts 'An error occurred sending mail..'
    #     puts  e.inspect
    #     puts
  #   #   end
  #   end
  #
  end
end
