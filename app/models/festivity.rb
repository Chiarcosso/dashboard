class Festivity < ApplicationRecord

  def self.is_festive?(date)
    Festivity.where(day: date.strftime('%d').to_i, month: date.strftime('%m').to_i).where("year is null or year = #{date.strftime('%Y')}").count > 0
  end

  def self.upsync_all
    MssqlReference.query({table: 'feste_nazionali'},'chiarcosso_test').each do |fs|
      fest  = Festivity.find_by(name: fs['descrizione'])
      Festivity.create(name: fs['descrizione'], day: fs['giorno'], month: fs['mese']) if fest.nil?
    end
  end

end
