class HumanResourcesMailer < ApplicationMailer


  default to: 'personale@chiarcosso.it'
  # default to: 'ufficioit@chiarcosso.com'

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
