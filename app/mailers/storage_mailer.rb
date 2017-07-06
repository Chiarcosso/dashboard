class StorageMailer < ApplicationMailer

  ADDRESS_LIST = ['magazzino@chiarcosso.it','fabio.boccacini@chiarcosso.com']

  def gear_request(application)
    @application = application
    # attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    m = mail(body: application.text, subject: 'Richiesta dotazione, '+application.person.complete_name)
    StorageMailer::ADDRESS_LIST.each do |address|
      m.to = address
      begin
      puts m
      puts m.deliver
      rescue EOFError,
              IOError,
              TimeoutError,
              Errno::ECONNRESET,
              Errno::ECONNABORTED,
              Errno::EPIPE,
              Errno::ETIMEDOUT,
              Net::SMTPAuthenticationError,
              Net::SMTPServerBusy,
              Net::SMTPSyntaxError,
              Net::SMTPUnknownError,
              OpenSSL::SSL::SSLError => e
              log_exception(e, options)
        puts
        puts 'An error occurred sending mail..'
        puts  e.inspect
        puts
      end
    end

  end
end
