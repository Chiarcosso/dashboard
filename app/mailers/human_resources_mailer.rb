class HumanResourcesMailer < ApplicationMailer

  mail_list: ['pierluigi.ottoborgo@chiarcosso.com','alessandra.copetto@chiarcosso.com','aurora.seffino@chiarcosso.com']
  def vacation_request(application)
    @application = application
    # byebug
    # mail(to: 'fabio.boccacini@chiarcosso.com', body: render('human_resources_mailer/vacation_request'), subject: 'Richiesta '+application.type, attachments: [application.filename => application.form]).deliver

    # attachments [:content_type => "application/pdf", :body => application.form]
    attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    mail_list.each do |address|
      mail(to: address, body: application.text, subject: 'Richiesta '+application.type+', '+application.person.complete_name).deliver
    end

  end

end
