class HumanResourcesMailer < ApplicationMailer


  ADDRESS_LIST = ['personale@chiarcosso.it']

  def vacation_request(application)
    @application = application
    attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    m = mail(body: application.text, subject: 'Richiesta '+application.type+', '+application.person.complete_name)
    HumanResourcesMailer::ADDRESS_LIST.each do |address|
      m.to = address
      begin
      m.deliver
      puts m
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
