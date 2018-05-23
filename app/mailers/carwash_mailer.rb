class CarwashMailer < ApplicationMailer

  default to: 'officina@chiarcosso.it'

  def check_up(vcs)
    vpcs = vcs.vehicle_performed_checks.not_ok

    vehicle = vcs.vehicle
    notify_to = ['officina@chiarcosso.it','ufficioit@chiarcosso.com']
    vpcs.each { |vc| notify_to << 'traffico@chiarcosso.it' if vc.blocking? }

    message = "Sessione controlli nr. #{vcs.id} (ODL: #{vcs.myofficina_reference})\n\n"\
    "#{vehicle.plate} - #{vehicle.model.complete_name}\n\n"

    message += vpcs.sort_by{ |vc| -vc.performed }.map{ |vpc| vpc.message }.join("\n")
    vpcs.each { |vc| notify_to << vc.notify_to.to_s.split(";")}
    notify_to = notify_to.flatten.uniq.join("\;")
    mail(body: message, subject: 'Controlli punto check-up', to: notify_to)
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

end
