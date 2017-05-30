class HumanResourcesMailer < ApplicationMailer

  def vacation_request(application)
    mail(to: 'fabio.boccacini@chiarcosso.com', subject: 'Richiesta '+application.type)
  end

end
