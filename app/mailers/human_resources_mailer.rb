class HumanResourcesMailer < ApplicationMailer

  def vacation_request(application)
    @application = application
    # byebug
    mail(to: 'fabio.boccacini@chiarcosso.com', subject: 'Richiesta '+application.type, attachments: [application.filename => application.form])
  end

end
