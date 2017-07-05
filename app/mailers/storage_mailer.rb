class StorageMailer < ApplicationMailer

  ADDRESS_LIST = ['magazzino@chiarcosso.it','fabio.boccacini@chiarcosso.com']

  def gear_request(application)
    @application = application
    # attachments[application.filename] = {:mime_type => 'application/pdf', :content => application.form }
    m = mail(body: application.text, subject: 'Richiesta dotazione, '+application.person.complete_name)
    StorageMailer::ADDRESS_LIST.each do |address|
      m.to = address
      puts m
      puts m.deliver
    end

  end
end
