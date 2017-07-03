class HumanResourcesMailer < ApplicationMailer


  ADDRESS_LIST = ['pierluigi.ottoborgo@chiarcosso.com','alessandra.copetto@chiarcosso.com','aurora.seffino@chiarcosso.com']

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
