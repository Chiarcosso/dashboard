class ErrorMailer < ApplicationMailer

  default to: 'errori.dashboard@chiarcosso.com'
  # default to: 'ufficioit@chiarcosso.com'

  def error_report(text,area)
    return if Rails.env == "development"
    mail(body: text, subject: "Report errori - #{area}")

  end

end
