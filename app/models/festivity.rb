class Festivity < ApplicationRecord

  def self.upsync_all
    MssqlReference.query({table: 'feste_nazionali'},'chiarcosso_test').each do |fs|
      fest  = Festivity.find_by(name: fs['descrizione'])
      Festivity.create(name: fs['descrizione'], day: fs['giorno'], month: fs['mese']) if fest.nil?
    end
  end

end
