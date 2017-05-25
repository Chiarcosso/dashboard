class Worksheet < ApplicationRecord
  resourcify

  belongs_to :vehicle
  scope :filter, ->(search) { joins(:vehicle).where("code LIKE ? OR ",'%'+search+'%') }

  def complete_name
    unless self.code.nil?
      self.code+' (Targa: '+self.vehicle.plate+')'
    else
      'Nuova scheda di lavoro'
    end
  end

  def hours_price
    self.hours.to_f * 30
  end

  def hours_complete_price
    ("%.2f" % self.hours_price.to_s+" € \n("+self.hours.to_s+' ore * 30,00€)').tr('.',',')
  end

  def materials_price
    self.hours.to_f * 5
  end

  def materials_complete_price
    ("%.2f" % self.materials_price.to_s+" € \n("+self.hours.to_s+' ore * 5,00€)').tr('.',',')
  end

  def self.findByCode code
    Worksheet.where(code: code).first
  end

  def self.filter(search)
    Worksheet.find_by_sql("SELECT DISTINCT w.* FROM worksheets w LEFT JOIN vehicle_informations i ON w.vehicle_id = i.vehicle_id WHERE w.code LIKE '%#{search}%' OR i.information LIKE '%#{search}%'")
  end
end
