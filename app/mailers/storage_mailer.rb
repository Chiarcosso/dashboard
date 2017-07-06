class StorageMailer < ApplicationMailer


  default to: 'magazzino@chiarcosso.it',
          bcc: ['ufficioit@chiarcosso.com','fabio.boccacini@chiarcosso.com']

  def gear_request(application)
    @application = application
    # attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    mail(body: application.text, subject: 'Richiesta dotazione, '+application.person.complete_name, to: 'magazzino@chiarcosso.it', bcc: ['ufficioit@chiarcosso.com','fabio.boccacini@chiarcosso.com'])
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
