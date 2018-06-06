class EurowinController < ApplicationController

  def self.get_notifications_from_odl(protocol)
    odl = EurowinController::get_worksheet(protocol)
    ewc = get_ew_client
    r = ewc.query("select * from autosegnalazioni where serialODL = #{odl['Serial']};")
    ewc.close
    r
  end

  def self.get_worksheet(protocol)
    protocol = protocol[/\d*/]
    ewc = get_ew_client
    r = ewc.query("select * from autoodl where protocollo = #{protocol} limit 1;").first
    ewc.close
    r
  end

  private

  def self.get_ew_client(db = ENV['RAILS_EUROS_DB'])
    Mysql2::Client.new username: ENV['RAILS_EUROS_USER'], password: ENV['RAILS_EUROS_PASS'], host: ENV['RAILS_EUROS_HOST'], port: ENV['RAILS_EUROS_PORT'], database: db
  end
end
