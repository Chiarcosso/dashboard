class HumanResourcesMailer < ApplicationMailer


  ADDRESS_LIST = ['personale@chiarcosso.it']

  def vacation_request(application)
    @application = application
    attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    m = mail(body: application.text, subject: 'Richiesta '+application.type+', '+application.person.complete_name)
    HumanResourcesMailer::ADDRESS_LIST.each do |address|
      m.to = address
      m.deliver
    end

  end


end
